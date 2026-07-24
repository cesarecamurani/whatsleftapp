# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecipesHelper, type: :helper do
  describe "#total_pages" do
    it "rounds partial pages up" do
      expect(helper.total_pages(13)).to eq(2)
    end

    it "returns zero when there are no results" do
      expect(helper.total_pages(0)).to eq(0)
    end

    it "caps at the maximum page number" do
      expect(helper.total_pages(10_000_000)).to eq(Pagination::MAX_PAGE_NUMBER)
    end
  end

  describe "#pagination_items" do
    it "returns nothing for a single page" do
      expect(helper.pagination_items(1, 1)).to eq([])
    end

    it "lists every page when they all fit" do
      expect(helper.pagination_items(2, 3)).to eq([1, 2, 3])
    end

    it "inserts a gap near the start" do
      expect(helper.pagination_items(1, 20)).to eq([1, 2, 3, :gap, 20])
    end

    it "inserts gaps on both sides in the middle" do
      expect(helper.pagination_items(10, 20)).to eq([1, :gap, 8, 9, 10, 11, 12, :gap, 20])
    end

    it "inserts a gap near the end" do
      expect(helper.pagination_items(20, 20)).to eq([1, :gap, 18, 19, 20])
    end

    it "clamps a current page beyond the total" do
      expect(helper.pagination_items(99, 3)).to eq([1, 2, 3])
    end
  end
end
