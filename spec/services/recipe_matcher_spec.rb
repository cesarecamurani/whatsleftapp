# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecipeMatcher, type: :service do
  describe ".call" do
    subject(:search_result) { described_class.call(ingredients:, limit:, page:) }

    let(:limit) { 10 }
    let(:page) { 1 }
    let(:results) { search_result.recipes }

    context "when ingredients are blank" do
      let(:ingredients) { [] }

      it "returns an empty search result" do
        expect(search_result).to be_a(RecipeSearchResult)
        expect(search_result.recipes).to be_empty
        expect(search_result.ingredients).to be_empty
        expect(search_result.page).to eq(1)
        expect(search_result.total_count).to eq(0)
      end
    end

    context "when returning search results" do
      let(:ingredients) { ["garlic"] }

      let!(:recipe) { create(:recipe, title: "Garlic Chicken") }

      before do
        create(
          :recipe_ingredient,
          recipe:,
          ingredient_text: "1 tablespoon garlic powder"
        )
      end

      it "returns RecipeMatch objects" do
        expect(results).to all(be_a(RecipeMatch))
        expect(results.first.recipe).to eq(recipe)
      end

      it "includes pagination metadata" do
        expect(search_result.page).to eq(1)
        expect(search_result.total_count).to eq(1)
      end
    end

    context "when no recipes match" do
      let(:ingredients) { ["dragonfruit"] }

      it "returns a zero total" do
        expect(results).to be_empty
        expect(search_result.total_count).to eq(0)
      end
    end

    context "when limit is invalid" do
      let(:ingredients) { ["chicken"] }
      let(:limit) { "invalid_limit" }

      before do
        create_list(:recipe, 3).each do |recipe|
          create(
            :recipe_ingredient,
            recipe:,
            ingredient_text: "chicken"
          )
        end
      end

      it "falls back to the default limit" do
        expect(results.size).to eq(3)
      end
    end

    context "when ingredients contain duplicates and formatting differences" do
      let(:ingredients) { [" Chicken ", "TOMATO", "", nil, "chicken"] }

      it "normalizes ingredients before searching" do
        normalized_results = described_class.call(
          ingredients: %w[chicken tomato]
        ).recipes

        expect(results.map(&:id)).to eq(normalized_results.map(&:id))
      end
    end

    context "when too many ingredients are provided" do
      let(:ingredients) do
        (1..(IngredientNormalizer::MAX_INGREDIENTS + 5)).map do |number|
          "ingredient-#{number}"
        end
      end

      it "keeps only the maximum number of ingredients" do
        expect(search_result.ingredients).to eq(
          ingredients.first(IngredientNormalizer::MAX_INGREDIENTS)
        )
      end
    end

    context "when an ingredient is too long" do
      let(:ingredients) do
        [
          "a" * IngredientNormalizer::MAX_INGREDIENT_LENGTH,
          "b" * (IngredientNormalizer::MAX_INGREDIENT_LENGTH + 1)
        ]
      end

      it "keeps the boundary value and rejects the overlong ingredient" do
        expect(search_result.ingredients).to eq(
          ["a" * IngredientNormalizer::MAX_INGREDIENT_LENGTH]
        )
      end
    end

    context "when an ingredient is too short" do
      let(:ingredients) do
        [
          "a" * (IngredientNormalizer::MIN_INGREDIENT_LENGTH - 1),
          "b" * IngredientNormalizer::MIN_INGREDIENT_LENGTH
        ]
      end

      it "rejects the short value and keeps the boundary value" do
        expect(search_result.ingredients).to eq(
          ["b" * IngredientNormalizer::MIN_INGREDIENT_LENGTH]
        )
      end
    end

    context "when recipes match ingredient text" do
      let(:ingredients) { ["garlic"] }

      let!(:recipe) { create(:recipe, title: "Garlic Chicken") }

      before do
        create(
          :recipe_ingredient,
          recipe:,
          ingredient_text: "1 tablespoon garlic powder"
        )
      end

      it "matches ingredients using partial text matching" do
        expect(results.map(&:recipe)).to include(recipe)
      end
    end

    context "when one low-coverage ingredient match appears in the title" do
      let(:ingredients) { ["garlic"] }

      let!(:recipe) { create(:recipe, title: "Garlic Baby Potatoes") }

      before do
        [
          "2 cloves garlic",
          "baby potatoes",
          "olive oil",
          "rosemary",
          "pepper",
          "salt"
        ].each do |ingredient|
          create(
            :recipe_ingredient,
            recipe:,
            ingredient_text: ingredient
          )
        end
      end

      it "includes the recipe" do
        expect(results.map(&:recipe)).to include(recipe)
      end
    end

    context "when a search term appears in the title but not the ingredients" do
      let(:ingredients) { ["garlic"] }

      let!(:recipe) { create(:recipe, title: "Garlic Baby Potatoes") }

      before do
        ["baby potatoes", "olive oil", "rosemary", "salt"].each do |ingredient|
          create(
            :recipe_ingredient,
            recipe:,
            ingredient_text: ingredient
          )
        end
      end

      it "does not include the recipe" do
        expect(results.map(&:recipe)).not_to include(recipe)
      end
    end

    context "when a title term did not match an ingredient" do
      let(:ingredients) { %w[garlic chicken] }

      let!(:recipe) { create(:recipe, title: "Garlic Weeknight Supper") }

      before do
        ["chicken breast", "onion", "rice", "pepper", "salt"].each do |ingredient|
          create(
            :recipe_ingredient,
            recipe:,
            ingredient_text: ingredient
          )
        end
      end

      it "does not use that term to qualify the recipe" do
        expect(results.map(&:recipe)).not_to include(recipe)
      end
    end

    context "when two ingredient lines match below the coverage threshold" do
      let(:ingredients) { ["garlic"] }

      let!(:recipe) { create(:recipe, title: "Herb Roasted Dinner") }

      before do
        [
          "fresh garlic",
          "garlic powder",
          "salt",
          "pepper",
          "olive oil",
          "onion",
          "thyme",
          "rosemary",
          "lemon",
          "water"
        ].each do |ingredient|
          create(
            :recipe_ingredient,
            recipe:,
            ingredient_text: ingredient
          )
        end
      end

      it "includes the recipe" do
        expect(results.map(&:recipe)).to include(recipe)
      end
    end

    context "when one ingredient line matches exactly 25 percent coverage" do
      let(:ingredients) { ["tomato"] }

      let!(:recipe) { create(:recipe, title: "Quick Side Dish") }

      before do
        ["tomato", "olive oil", "pepper", "salt"].each do |ingredient|
          create(
            :recipe_ingredient,
            recipe:,
            ingredient_text: ingredient
          )
        end
      end

      it "includes the recipe" do
        expect(results.map(&:recipe)).to include(recipe)
      end
    end

    context "when one incidental match is below 25 percent coverage" do
      let(:ingredients) { ["garlic"] }

      let!(:recipe) { create(:recipe, title: "Weeknight Dinner") }

      before do
        ["garlic", "onion", "rice", "pepper", "salt"].each do |ingredient|
          create(
            :recipe_ingredient,
            recipe:,
            ingredient_text: ingredient
          )
        end
      end

      it "does not include the recipe" do
        expect(results.map(&:recipe)).not_to include(recipe)
      end
    end

    context "when an unrelated pantry ingredient is added" do
      let!(:recipe) { create(:recipe, title: "Garlic Weeknight Dinner") }

      before do
        [
          "garlic",
          "onion",
          "rice",
          "pepper",
          "salt",
          "olive oil",
          "thyme",
          "water"
        ].each do |ingredient|
          create(
            :recipe_ingredient,
            recipe:,
            ingredient_text: ingredient
          )
        end
      end

      it "keeps a recipe that was valid for the original ingredients" do
        original_results =
          described_class.call(ingredients: ["garlic"]).recipes
        expanded_results =
          described_class.call(ingredients: %w[garlic chicken]).recipes

        expect(original_results.map(&:recipe)).to include(recipe)
        expect(expanded_results.map(&:recipe)).to include(recipe)
      end
    end

    context "when calculating recipe coverage" do
      let(:ingredients) { %w[chicken garlic] }

      let!(:recipe) { create(:recipe, title: "Partially Covered Recipe") }

      before do
        ["chicken breast", "garlic", "salt", "pepper"].each do |ingredient|
          create(
            :recipe_ingredient,
            recipe:,
            ingredient_text: ingredient
          )
        end
      end

      it "returns the matched ingredient coverage ratio" do
        expect(results.first.coverage_ratio.to_f).to eq(0.5)
      end

      it "calculates missing recipe ingredients" do
        expect(results.first.missing_recipe_ingredients_count).to eq(2)
        expect(results.first.missing_recipe_ingredients.map(&:ingredient_text))
          .to eq(%w[salt pepper])
      end

      it "returns matched search terms in search-input order" do
        expect(results.first.matched_terms).to eq(%w[chicken garlic])
      end

      it "returns no unmatched search terms when every term matches" do
        expect(results.first.unmatched_search_terms).to be_empty
      end

      it "preloads recipe ingredients for the displayed results" do
        expect(results.first.recipe.association(:recipe_ingredients))
          .to be_loaded
      end
    end

    context "when some search terms do not match" do
      let(:ingredients) { %w[chicken garlic tomato] }

      let!(:recipe) { create(:recipe, title: "Chicken Garlic Pasta") }

      before do
        %w[chicken breast garlic].each do |ingredient|
          create(
            :recipe_ingredient,
            recipe:,
            ingredient_text: ingredient
          )
        end
      end

      it "returns the matched search terms" do
        expect(results.first.matched_terms).to eq(%w[chicken garlic])
      end

      it "returns the unmatched search term" do
        expect(results.first.unmatched_search_terms).to eq(%w[tomato])
      end
    end

    context "when search terms are entered out of alphabetical order" do
      let(:ingredients) { %w[tomato chicken garlic] }

      let!(:recipe) { create(:recipe, title: "Ordered Terms Recipe") }

      before do
        %w[chicken breast garlic clove tomato].each do |ingredient|
          create(
            :recipe_ingredient,
            recipe:,
            ingredient_text: ingredient
          )
        end
      end

      it "preserves search-input order for matched terms" do
        expect(results.first.matched_terms).to eq(
          %w[tomato chicken garlic]
        )
      end
    end

    context "when an ingredient matches multiple recipe ingredients" do
      let(:ingredients) { ["garlic"] }

      let!(:recipe) { create(:recipe, title: "Garlic Heavy Recipe") }

      before do
        ["fresh garlic", "garlic powder"].each do |ingredient|
          create(
            :recipe_ingredient,
            recipe:,
            ingredient_text: ingredient
          )
        end
      end

      it "counts matched search terms once per recipe" do
        expect(results.first.matched_terms_count).to eq(1)
      end

      it "counts matching ingredient rows separately" do
        expect(results.first.matched_ingredients_count).to eq(2)
      end
    end

    context "when ranking recipes by coverage" do
      let(:ingredients) { %w[chicken garlic] }

      let!(:high_coverage_recipe) do
        create(:recipe, title: "High Coverage")
      end

      let!(:low_coverage_recipe) do
        create(:recipe, title: "Low Coverage")
      end

      before do
        %w[chicken garlic].each do |ingredient|
          create(
            :recipe_ingredient,
            recipe: high_coverage_recipe,
            ingredient_text: ingredient
          )
        end

        %w[chicken garlic onion salt].each do |ingredient|
          create(
            :recipe_ingredient,
            recipe: low_coverage_recipe,
            ingredient_text: ingredient
          )
        end
      end

      it "ranks recipes with better coverage first" do
        expect(results.first.recipe).to eq(high_coverage_recipe)
      end
    end

    context "when a lower-coverage recipe matches more search terms" do
      let(:ingredients) { %w[chicken garlic] }

      let!(:more_matches_recipe) do
        create(:recipe, title: "Pantry Dinner")
      end

      let!(:fewer_matches_recipe) do
        create(:recipe, title: "Quick Dinner")
      end

      before do
        %w[chicken garlic onion salt pepper].each do |ingredient|
          create(
            :recipe_ingredient,
            recipe: more_matches_recipe,
            ingredient_text: ingredient
          )
        end

        create(
          :recipe_ingredient,
          recipe: fewer_matches_recipe,
          ingredient_text: "chicken"
        )
      end

      it "ranks the recipe matching more terms first" do
        expect(results.first.recipe).to eq(more_matches_recipe)
      end
    end

    context "when title relevance competes with higher coverage" do
      let(:ingredients) { ["garlic"] }

      let!(:title_match_recipe) do
        create(:recipe, title: "Garlic Baby Potatoes")
      end

      let!(:higher_coverage_recipe) do
        create(:recipe, title: "Savory Side Dish")
      end

      before do
        ["garlic", "potatoes", "oil", "rosemary", "pepper", "salt"].each do |ingredient|
          create(
            :recipe_ingredient,
            recipe: title_match_recipe,
            ingredient_text: ingredient
          )
        end

        ["garlic", "oil", "salt"].each do |ingredient|
          create(
            :recipe_ingredient,
            recipe: higher_coverage_recipe,
            ingredient_text: ingredient
          )
        end
      end

      it "ranks the title match first" do
        expect(results.first.recipe).to eq(title_match_recipe)
      end
    end

    context "when applying the limit" do
      let(:ingredients) { ["chicken"] }
      let(:limit) { 1 }

      before do
        create_list(:recipe, 3).each do |recipe|
          create(
            :recipe_ingredient,
            recipe:,
            ingredient_text: "chicken"
          )
        end
      end

      it "returns only the requested number of recipes" do
        expect(results.size).to eq(1)
      end
    end

    context "when paginating results" do
      let(:ingredients) { ["chicken"] }
      let(:limit) { 2 }
      let(:page) { 2 }

      let!(:recipes) do
        [
          create(:recipe, title: "A Chicken"),
          create(:recipe, title: "B Chicken"),
          create(:recipe, title: "C Chicken"),
          create(:recipe, title: "D Chicken")
        ]
      end

      before do
        recipes.each do |recipe|
          create(
            :recipe_ingredient,
            recipe:,
            ingredient_text: "chicken"
          )
        end
      end

      it "returns the requested page of recipes" do
        expect(results.map(&:title)).to eq(["C Chicken", "D Chicken"])
        expect(search_result.page).to eq(2)
        expect(search_result.total_count).to eq(4)
      end
    end

    context "when more results exist" do
      let(:ingredients) { ["chicken"] }
      let(:limit) { 2 }

      before do
        create_list(:recipe, 3).each do |recipe|
          create(
            :recipe_ingredient,
            recipe:,
            ingredient_text: "chicken"
          )
        end
      end

      it "reports the total across all pages" do
        expect(results.size).to eq(2)
        expect(search_result.total_count).to eq(3)
      end
    end

    context "when page is beyond the last page" do
      let(:ingredients) { ["chicken"] }
      let(:limit) { 2 }
      let(:page) { 99 }

      before do
        create_list(:recipe, 3).each do |recipe|
          create(
            :recipe_ingredient,
            recipe:,
            ingredient_text: "chicken"
          )
        end
      end

      it "returns an empty page" do
        expect(search_result.page).to eq(99)
        expect(results).to be_empty
        expect(search_result.total_count).to eq(3)
      end
    end

    context "when page is invalid" do
      let(:ingredients) { ["chicken"] }
      let(:page) { "invalid_page" }

      before do
        create(
          :recipe_ingredient,
          recipe: create(:recipe),
          ingredient_text: "chicken"
        )
      end

      it "falls back to the first page" do
        expect(search_result.page).to eq(1)
        expect(results.size).to eq(1)
      end
    end

    context "when recipes are otherwise equivalent" do
      let(:ingredients) { ["chicken"] }

      let!(:first_recipe) do
        create(:recipe, title: "Apple Chicken")
      end

      let!(:second_recipe) do
        create(:recipe, title: "Zebra Chicken")
      end

      before do
        [first_recipe, second_recipe].each do |recipe|
          create(
            :recipe_ingredient,
            recipe:,
            ingredient_text: "chicken"
          )
        end
      end

      it "uses title as a deterministic tie breaker" do
        expect(results.first.recipe).to eq(first_recipe)
      end
    end
  end
end
