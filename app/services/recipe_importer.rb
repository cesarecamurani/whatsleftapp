# frozen_string_literal: true

class RecipeImporter
  BATCH_SIZE = 1_000

  def self.call(path:)
    new(path).call
  end

  def initialize(path)
    @path = path
  end

  def call
    Recipe.transaction { import_recipes(load_recipes) }
  end

  private

  attr_reader :path

  def load_recipes
    raise ArgumentError, "File not found: #{path}" unless File.file?(path)

    JSON.parse(File.read(path)).tap do |recipes|
      unless recipes.is_a?(Array)
        raise ArgumentError, "Expected JSON root to be an array"
      end
    end
  rescue JSON::ParserError => e
    raise ArgumentError, "Invalid JSON file: #{e.message}"
  end

  def import_recipes(recipes)
    valid_recipes, skipped_recipes = partition_recipes(recipes)

    clear_existing_data

    recipe_ids = insert_recipes(valid_recipes)
    ingredients_count = insert_ingredients(valid_recipes, recipe_ids)

    build_import_result(
      recipes_count: valid_recipes.size,
      ingredients_count:,
      skipped_recipes:
    )
  end

  def clear_existing_data
    RecipeIngredient.delete_all
    Recipe.delete_all
  end

  def partition_recipes(recipes)
    recipes.each_with_index.with_object([ [], [] ]) do |(recipe, index), (valid, skipped)|
      reason = invalid_reason(recipe)

      reason ? skipped << skipped_recipe(recipe, index, reason) : valid << recipe
    end
  end

  def invalid_reason(recipe)
    return "record is not an object" unless recipe.is_a?(Hash)
    return "title is missing" if recipe["title"].blank?
    return "ingredients must be an array" unless recipe["ingredients"].is_a?(Array)

    nil
  end

  def skipped_recipe(recipe, index, reason)
    {
      index:,
      title: recipe.is_a?(Hash) ? recipe["title"] : nil,
      reason:
    }
  end

  def insert_recipes(recipes)
    timestamp = Time.current
    recipe_ids = []

    recipes.each_slice(BATCH_SIZE) do |batch|
      rows = batch.map do |recipe|
        recipe_id = SecureRandom.uuid
        recipe_ids << recipe_id

        recipe_row(recipe, recipe_id, timestamp)
      end

      Recipe.insert_all!(rows)
    end

    recipe_ids
  end

  def recipe_row(recipe, recipe_id, timestamp)
    {
      id: recipe_id,
      title: recipe["title"],
      prep_time: recipe["prep_time"],
      cook_time: recipe["cook_time"],
      rating: recipe["ratings"],
      category: normalize_category(recipe["category"]),
      image_url: resolve_image_url(recipe["image"]),
      created_at: timestamp,
      updated_at: timestamp
    }
  end

  def insert_ingredients(recipes, recipe_ids)
    timestamp = Time.current
    batch = []
    imported_count = 0

    recipes.zip(recipe_ids).each do |recipe, recipe_id|
      normalized_ingredients(recipe["ingredients"]).each do |ingredient_text|
        batch << ingredient_row(recipe_id, ingredient_text, timestamp)

        next unless batch.size == BATCH_SIZE

        RecipeIngredient.insert_all!(batch)

        imported_count += batch.size

        batch.clear
      end
    end

    if batch.any?
      RecipeIngredient.insert_all!(batch)

      imported_count += batch.size
    end

    imported_count
  end

  def normalized_ingredients(ingredients)
    ingredients
      .filter_map { |ingredient| ingredient.to_s.strip.downcase.presence }
      .uniq
  end

  def normalize_category(category)
    return if category.blank?

    Nokogiri::HTML.fragment(category.to_s).text.strip.presence
  end

  def resolve_image_url(url)
    RecipeImageUrlResolver.call(url)
  end

  def ingredient_row(recipe_id, ingredient_text, timestamp)
    {
      recipe_id:,
      ingredient_text:,
      created_at: timestamp,
      updated_at: timestamp
    }
  end

  def build_import_result(recipes_count:, ingredients_count:, skipped_recipes:)
    {
      recipes_count:,
      ingredients_count:,
      skipped_recipes:
    }
  end
end
