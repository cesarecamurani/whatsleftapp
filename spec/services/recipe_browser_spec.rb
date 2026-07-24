# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecipeBrowser, type: :service do
  describe ".call" do
    subject(:result) { described_class.call(**options) }

    let(:options) { {} }

    context "with no filters" do
      before { create_list(:recipe, 2) }

      it "returns a RecipeSearchResult" do
        expect(result).to be_a(RecipeSearchResult)
      end

      it "returns the matching recipes" do
        expect(result.recipes.size).to eq(2)
      end

      it "reports the total count" do
        expect(result.total_count).to eq(2)
      end
    end

    context "when filtering by category" do
      let(:options) { { category: "Dessert" } }
      let!(:dessert) { create(:recipe, category: "Dessert") }

      before { create(:recipe, category: "Main") }

      it "returns only recipes in the category" do
        expect(result.recipes).to contain_exactly(dessert)
      end

      it "counts only recipes in the category" do
        expect(result.total_count).to eq(1)
      end
    end

    context "when filtering by minimum rating" do
      let(:options) { { min_rating: "4" } }
      let!(:highly_rated) { create(:recipe, rating: 4.5) }

      before { create(:recipe, rating: 2.0) }

      it "returns only recipes at or above the rating" do
        expect(result.recipes).to contain_exactly(highly_rated)
      end
    end

    context "when results span multiple pages" do
      let(:options) { { page: 1, limit: 2 } }

      before { create_list(:recipe, 3, rating: 4.0) }

      it "returns only the requested page of results" do
        expect(result.recipes.size).to eq(2)
      end

      it "reports the total across all pages, not just the page" do
        expect(result.total_count).to eq(3)
      end
    end

    context "when on the last page" do
      let(:options) { { page: 2, limit: 2 } }

      before { create_list(:recipe, 3, rating: 4.0) }

      it "echoes the requested page" do
        expect(result.page).to eq(2)
      end
    end

    context "when the page is invalid" do
      let(:options) { { page: "invalid" } }

      before { create(:recipe) }

      it "falls back to the first page" do
        expect(result.page).to eq(1)
      end
    end

    context "when ordering equal-rated recipes" do
      let!(:ziti_soup) { create(:recipe, title: "Ziti Soup", rating: 4.0) }
      let!(:apple_pie) { create(:recipe, title: "Apple Pie", rating: 4.0) }

      it "orders by title as a deterministic tie breaker" do
        expect(result.recipes).to eq([apple_pie, ziti_soup])
      end
    end
  end
end
