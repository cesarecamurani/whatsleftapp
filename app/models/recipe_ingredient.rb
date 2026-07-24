# frozen_string_literal: true

class RecipeIngredient < ApplicationRecord
  belongs_to :recipe
end
