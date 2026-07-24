# frozen_string_literal: true

class IngredientNormalizer
  MAX_INGREDIENTS = 25
  MIN_INGREDIENT_LENGTH = 3
  MAX_INGREDIENT_LENGTH = 100

  def self.call(values)
    new(values).call
  end

  def initialize(values)
    @values = values
  end

  def call
    Array(values)
      .filter_map do |value|
        normalized = value.to_s.strip.downcase.presence

        next if normalized.nil?
        next unless normalized.length.between?(
          MIN_INGREDIENT_LENGTH,
          MAX_INGREDIENT_LENGTH
        )

        normalized
      end.uniq.first(MAX_INGREDIENTS)
  end

  private

  attr_reader :values
end
