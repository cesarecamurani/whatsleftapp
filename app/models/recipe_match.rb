# frozen_string_literal: true

class RecipeMatch
  extend ActiveSupport::Delegation

  attr_reader :recipe,
              :matched_terms,
              :unmatched_search_terms,
              :coverage_ratio,
              :missing_recipe_ingredients

  delegate_missing_to :recipe

  class << self
    def term_matches?(ingredient_text, term)
      ingredient_text.to_s.downcase.include?(term)
    end

    def from_recipe(
      recipe:,
      search_ingredients:,
      matched_terms: nil,
      coverage_ratio: nil
    )
      recipe_ingredients = recipe.recipe_ingredients.to_a

      calculated_matched_terms = search_ingredients.select do |term|
        recipe_ingredients.any? do |ingredient|
          term_matches?(ingredient.ingredient_text, term)
        end
      end

      matched_ingredients = recipe_ingredients.select do |ingredient|
        calculated_matched_terms.any? do |term|
          term_matches?(ingredient.ingredient_text, term)
        end
      end

      if recipe_ingredients.any?
        calculated_coverage_ratio = matched_ingredients.size.to_f / recipe_ingredients.size
      end

      missing_recipe_ingredients =
        recipe_ingredients.reject do |ingredient|
          search_ingredients.any? do |term|
            term_matches?(ingredient.ingredient_text, term)
          end
        end

      new(
        recipe:,
        search_ingredients:,
        matched_terms: matched_terms || calculated_matched_terms,
        coverage_ratio: coverage_ratio || calculated_coverage_ratio,
        missing_recipe_ingredients:
      )
    end
  end

  def initialize(
    recipe:,
    search_ingredients:,
    matched_terms: nil,
    coverage_ratio: nil,
    missing_recipe_ingredients: []
  )
    @recipe = recipe
    @matched_terms = search_ingredients & Array(matched_terms || recipe_matched_terms)
    @unmatched_search_terms = search_ingredients - @matched_terms
    @coverage_ratio = coverage_ratio || recipe_coverage_ratio
    @missing_recipe_ingredients = missing_recipe_ingredients
  end

  private

  def recipe_matched_terms
    recipe.matched_terms if recipe.respond_to?(:matched_terms)
  end

  def recipe_coverage_ratio
    recipe.coverage_ratio if recipe.respond_to?(:coverage_ratio)
  end
end
