# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecipeCard do
  let(:recipe) { create(:recipe, title: "Roast Chicken", rating: 4.5) }

  before do
    create(:recipe_ingredient, recipe:, ingredient_text: "chicken breast")
    create(:recipe_ingredient, recipe:, ingredient_text: "garlic")
  end

  describe ".for_browse" do
    subject(:card) { described_class.for_browse(recipe) }

    it "exposes the core recipe attributes" do
      aggregate_failures do
        expect(card.id).to eq(recipe.id)
        expect(card.title).to eq("Roast Chicken")
        expect(card.image_url).to eq(recipe.image_url)
      end
    end

    it "exposes the rating and full ingredient list" do
      aggregate_failures do
        expect(card.rating).to eq(4.5)
        expect(card.recipe_ingredients.map(&:ingredient_text))
          .to contain_exactly("chicken breast", "garlic")
      end
    end

    it "omits search match metadata" do
      aggregate_failures do
        expect(card.coverage_ratio).to be_nil
        expect(card.matched_terms).to eq([])
        expect(card.unmatched_search_terms).to eq([])
        expect(card.missing_recipe_ingredients).to eq([])
      end
    end
  end

  describe ".for_search" do
    subject(:card) { described_class.for_search(match) }

    let(:match) do
      RecipeMatch.from_recipe(recipe:, search_ingredients: %w[chicken tomato])
    end

    it "exposes the core recipe attributes" do
      aggregate_failures do
        expect(card.id).to eq(recipe.id)
        expect(card.title).to eq("Roast Chicken")
        expect(card.image_url).to eq(recipe.image_url)
      end
    end

    it "exposes the search match metadata" do
      aggregate_failures do
        expect(card.coverage_ratio).to be_present
        expect(card.matched_terms).to eq(%w[chicken])
        expect(card.unmatched_search_terms).to eq(%w[tomato])
        expect(card.missing_recipe_ingredients.map(&:ingredient_text))
          .to contain_exactly("garlic")
      end
    end

    it "omits the rating and full ingredient list" do
      aggregate_failures do
        expect(card.rating).to be_nil
        expect(card.recipe_ingredients).to eq([])
      end
    end
  end
end
