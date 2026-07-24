# frozen_string_literal: true

class RecipesController < ApplicationController
  RATING_FILTER_VALUES = %w[1 2 3 4 5].freeze

  def index
    @search_submitted = params.key?(:ingredients)
    @ingredients = IngredientNormalizer.call(params[:ingredients])

    return unless @ingredients.any?

    result = RecipeMatcher.call(
      ingredients: @ingredients,
      page: params[:page]
    )

    assign_paginated_results(result)
  end

  def show
    @recipe = Recipe.includes(:recipe_ingredients).find(params[:id])
    @ingredients = IngredientNormalizer.call(params[:ingredients])

    return unless @ingredients.any?

    @match = RecipeMatch.from_recipe(
      recipe: @recipe,
      search_ingredients: @ingredients
    )
  end

  def browse
    @categories = Recipe.distinct_categories
    @selected_category = params[:category].presence
    @selected_rating = normalize_rating(params[:rating])

    result = RecipeBrowser.call(
      category: @selected_category,
      min_rating: @selected_rating,
      page: params[:page]
    )

    assign_paginated_results(result)
  end

  private

  def normalize_rating(value)
    normalized = value.to_s

    normalized if RATING_FILTER_VALUES.include?(normalized)
  end

  def assign_paginated_results(result)
    @recipes = result.recipes
    @page = result.page
    @total_count = result.total_count
  end
end
