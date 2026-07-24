# frozen_string_literal: true

module Pagination
  MAX_PAGE_NUMBER = 1_000
  DEFAULT_PAGE_SIZE = 12
  MAX_PAGE_SIZE = 100

  module_function

  def normalize_page(value)
    Integer(value).clamp(1, MAX_PAGE_NUMBER)
  rescue ArgumentError, TypeError
    1
  end

  def normalize_page_size(value)
    Integer(value).clamp(1, MAX_PAGE_SIZE)
  rescue ArgumentError, TypeError
    DEFAULT_PAGE_SIZE
  end

  def page_offset(page, page_size)
    (page - 1) * page_size
  end
end
