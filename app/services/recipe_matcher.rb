# frozen_string_literal: true

class RecipeMatcher
  include Pagination

  MINIMUM_RECIPE_COVERAGE = 0.25
  MINIMUM_MATCHED_INGREDIENTS = 2
  MINIMUM_MATCHED_TERMS = 1

  def self.call(...)
    new(...).call
  end

  def initialize(ingredients:, limit: DEFAULT_PAGE_SIZE, page: 1)
    @ingredients = IngredientNormalizer.call(ingredients)
    @limit = normalize_page_size(limit)
    @page = normalize_page(page)
  end

  def call
    return empty_result if ingredients.empty?

    recipes = fetch_recipes(limit)
    total_count = total_count_for(recipes)

    preload_recipe_ingredients(recipes)

    build_search_result(recipes, total_count)
  end

  private

  attr_reader :ingredients, :limit, :page

  def fetch_recipes(fetch_limit, query_offset: page_offset(page, limit))
    Recipe.find_by_sql(
      RecipeMatcherQuery.call(
        ingredients:,
        minimum_matched_terms: MINIMUM_MATCHED_TERMS,
        minimum_matched_ingredients: MINIMUM_MATCHED_INGREDIENTS,
        minimum_recipe_coverage: MINIMUM_RECIPE_COVERAGE,
        limit: fetch_limit,
        offset: query_offset
      )
    )
  end

  def build_search_result(recipes, total_count)
    RecipeSearchResult.new(
      recipes: recipes.map do |recipe|
        RecipeMatch.from_recipe(
          recipe:,
          search_ingredients: ingredients,
          matched_terms: recipe.matched_terms,
          coverage_ratio: recipe.coverage_ratio
        )
      end,
      ingredients:,
      page:,
      total_count:
    )
  end

  def empty_result
    RecipeSearchResult.new(
      recipes: [],
      ingredients:,
      page:,
      total_count: 0
    )
  end

  def total_count_for(matched_recipes)
    row = matched_recipes.first
    row ||= fetch_recipes(1, query_offset: 0).first if page > 1

    row ? row.total_count.to_i : 0
  end

  def preload_recipe_ingredients(recipes)
    return if recipes.empty?

    ActiveRecord::Associations::Preloader.new(
      records: recipes,
      associations: :recipe_ingredients
    ).call
  end
end
