# frozen_string_literal: true

class Recipe < ApplicationRecord
  has_many :recipe_ingredients, dependent: :delete_all

  scope :with_category, ->(category) { where(category: category) }
  scope :rated_at_least, ->(rating) { where(rating: rating.to_d..) }
  scope :ordered_for_browse, lambda {
    order(Arel.sql("rating DESC NULLS LAST"), title: :asc, id: :asc)
  }

  class << self
    def distinct_categories
      where.not(category: [nil, ""])
        .distinct
        .order(:category)
        .pluck(:category)
    end

    def browse_filtered(category: nil, min_rating: nil)
      scope = includes(:recipe_ingredients)
      scope = scope.with_category(category) if category.present?
      scope = scope.rated_at_least(min_rating) if min_rating.present?
      scope.ordered_for_browse
    end
  end
end
