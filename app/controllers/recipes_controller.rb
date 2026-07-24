# frozen_string_literal: true

class RecipesController < ApplicationController
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

  private

  def assign_paginated_results(result)
    @recipes = result.recipes
    @page = result.page
    @total_count = result.total_count
  end
end
