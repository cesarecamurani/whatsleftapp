# frozen_string_literal: true

class RecipeCard
  def self.for_search(match)
    new(match, matched: true)
  end

  def self.for_browse(recipe)
    new(recipe, matched: false)
  end

  def initialize(record, matched:)
    @record = record
    @matched = matched
  end

  def id
    record.id
  end

  def title
    record.title
  end

  def image_url
    record.image_url
  end

  def rating
    record.rating unless matched?
  end

  def recipe_ingredients
    return [] if matched?

    record.recipe_ingredients
  end

  def coverage_ratio
    record.coverage_ratio if matched?
  end

  def matched_terms
    return [] unless matched?

    Array(record.matched_terms)
  end

  def unmatched_search_terms
    return [] unless matched?

    Array(record.unmatched_search_terms)
  end

  def missing_recipe_ingredients
    return [] unless matched?

    Array(record.missing_recipe_ingredients)
  end

  private

  attr_reader :record

  def matched?
    @matched
  end
end
