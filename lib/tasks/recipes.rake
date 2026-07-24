# frozen_string_literal: true

namespace :recipes do
  desc "Import recipes from the JSON dataset"

  task import: :environment do
    result = RecipeImporter.call(
      path: Rails.root.join("data/recipes.json")
    )

    puts "Recipes imported: #{result[:recipes_count]}"
    puts "Ingredients imported: #{result[:ingredients_count]}"
    puts "Recipes skipped: #{result[:skipped_recipes].count}"

    next if result[:skipped_recipes].empty?

    puts
    puts "Skipped recipes:"

    result[:skipped_recipes].each do |recipe|
      puts "- #{recipe[:title].presence || '(no title)'}: #{recipe[:reason]}"
    end
  end

  desc "Resolve existing recipe image URLs"

  task resolve_image_urls: :environment do
    updated_count = 0

    Recipe.find_each do |recipe|
      resolved_url = RecipeImageUrlResolver.call(recipe.image_url)

      next if resolved_url == recipe.image_url

      recipe.update_column(:image_url, resolved_url)
      updated_count += 1
    end

    puts "Updated #{updated_count} recipe image URLs"
  end
end
