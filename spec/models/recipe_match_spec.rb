# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecipeMatch do
  describe ".from_recipe" do
    subject(:match) do
      described_class.from_recipe(
        recipe:,
        search_ingredients: %w[chicken garlic tomato]
      )
    end

    let(:recipe) { create(:recipe) }
    let(:ingredient_texts) { ["chicken breast", "garlic", "salt", "pepper"] }

    before do
      ingredient_texts.each do |ingredient_text|
        create(:recipe_ingredient, recipe:, ingredient_text:)
      end
    end

    it "calculates matched and unmatched search terms" do
      aggregate_failures do
        expect(match.matched_terms).to eq(%w[chicken garlic])
        expect(match.unmatched_search_terms).to eq(%w[tomato])
      end
    end

    it "calculates recipe ingredient coverage" do
      expect(match.coverage_ratio).to eq(0.5)
    end

    it "identifies recipe ingredients not covered by the search" do
      expect(match.missing_recipe_ingredients.map(&:ingredient_text))
        .to eq(%w[salt pepper])
    end

    context "when the recipe has no ingredients" do
      let(:ingredient_texts) { [] }

      it "returns no coverage and leaves every search term unmatched" do
        aggregate_failures do
          expect(match.coverage_ratio).to be_nil
          expect(match.matched_terms).to be_empty
          expect(match.unmatched_search_terms).to eq(%w[chicken garlic tomato])
          expect(match.missing_recipe_ingredients).to be_empty
        end
      end
    end
  end

  describe "#initialize" do
    subject(:match) do
      described_class.new(
        recipe:,
        search_ingredients: %w[chicken garlic tomato]
      )
    end

    let(:recipe) do
      build_stubbed(
        :recipe,
        title: "Chicken Pasta",
        rating: 4.5
      ).tap do |record|
        record.define_singleton_method(:matched_terms) do
          %w[garlic chicken]
        end
      end
    end

    it "exposes the wrapped recipe" do
      expect(match.recipe).to eq(recipe)
    end

    it "orders matched terms by the search input" do
      expect(match.matched_terms).to eq(%w[chicken garlic])
    end

    it "returns unmatched search terms" do
      expect(match.unmatched_search_terms).to eq(%w[tomato])
    end

    it "returns no unmatched terms when all search ingredients match" do
      expect(
        described_class.new(
          recipe:,
          search_ingredients: %w[chicken garlic]
        ).unmatched_search_terms
      ).to be_empty
    end
  end

  describe "delegation" do
    subject(:match) do
      described_class.new(
        recipe:,
        search_ingredients: %w[chicken]
      )
    end

    let(:recipe) do
      create(:recipe, title: "Delegated Recipe", rating: 4.2)
    end

    before do
      create(:recipe_ingredient, recipe:, ingredient_text: "chicken")

      recipe.reload

      recipe.define_singleton_method(:matched_terms) do
        %w[chicken]
      end
    end

    it "delegates ordinary recipe attributes" do
      expect(match.title).to eq("Delegated Recipe")
      expect(match.rating).to eq(4.2)
    end

    it "delegates associations" do
      expect(match.recipe_ingredients.map(&:ingredient_text))
        .to eq(["chicken"])
    end
  end
end
