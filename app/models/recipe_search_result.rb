# frozen_string_literal: true

class RecipeSearchResult
  attr_reader :recipes, :ingredients, :page, :total_count

  def initialize(recipes:, ingredients:, page:, total_count:)
    @recipes = recipes
    @ingredients = ingredients
    @page = page
    @total_count = total_count
  end
end
