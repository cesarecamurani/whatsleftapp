# frozen_string_literal: true

module RecipesHelper
  MISSING_INGREDIENTS_PREVIEW_LIMIT = 3
  PAGINATION_WINDOW = 2

  RATING_OPTIONS = [
    ["Any rating", ""],
    ["5+", "5"],
    ["4+", "4"],
    ["3+", "3"],
    ["2+", "2"],
    ["1+", "1"]
  ].freeze

  def recipe_category_options(categories)
    categories.map do |category|
      [category, category]
    end
  end

  def recipe_rating_options
    RATING_OPTIONS
  end

  def max_ingredients
    IngredientNormalizer::MAX_INGREDIENTS
  end

  def min_ingredient_length
    IngredientNormalizer::MIN_INGREDIENT_LENGTH
  end

  def max_ingredient_length
    IngredientNormalizer::MAX_INGREDIENT_LENGTH
  end

  def total_pages(total_count)
    [(total_count.to_f / Pagination::DEFAULT_PAGE_SIZE).ceil, Pagination::MAX_PAGE_NUMBER].min
  end

  def pagination_items(current_page, page_count)
    return [] if page_count <= 1

    current = current_page.clamp(1, page_count)

    visible = [1, page_count, *((current - PAGINATION_WINDOW)..(current + PAGINATION_WINDOW))]
      .select { |page| page.between?(1, page_count) }
      .uniq
      .sort

    with_pagination_gaps(visible)
  end

  private

  def with_pagination_gaps(pages)
    pages.each_with_index.flat_map do |page, index|
      gap = index.positive? && page - pages[index - 1] > 1

      gap ? [:gap, page] : [page]
    end
  end
end
