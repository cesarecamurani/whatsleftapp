# frozen_string_literal: true

class RecipeBrowser
  include Pagination

  def self.call(...)
    new(...).call
  end

  def initialize(category: nil, min_rating: nil, page: 1, limit: DEFAULT_PAGE_SIZE)
    @category = category.presence
    @min_rating = min_rating.presence
    @page = normalize_page(page)
    @limit = normalize_page_size(limit)
  end

  def call
    recipes = scope.offset(page_offset(page, limit)).limit(limit).to_a

    RecipeSearchResult.new(
      recipes:,
      ingredients: [],
      page:,
      total_count: scope.count
    )
  end

  private

  attr_reader :category, :min_rating, :page, :limit

  def scope
    @scope ||= Recipe.browse_filtered(category:, min_rating:)
  end
end
