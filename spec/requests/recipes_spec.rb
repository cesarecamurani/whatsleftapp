# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Recipes", type: :request do
  describe "GET /search" do
    context "without ingredients" do
      it "returns success" do
        get search_path

        expect(response).to have_http_status(:ok)
      end

      it "does not call RecipeMatcher" do
        expect(RecipeMatcher).not_to receive(:call)

        get search_path
      end

      it "renders the search page without a no-results message" do
        get search_path

        expect(response.body).to include("Match recipes")
        expect(response.body).not_to include("No recipes matched those ingredients")
      end
    end

    context "with ingredients[]" do
      subject(:perform_request) do
        get search_path, params: { ingredients: raw_ingredients }
      end

      let(:raw_ingredients) { [" Chicken ", "TOMATO", "", "chicken"] }
      let(:normalized_ingredients) { %w[chicken tomato] }
      let(:recipe) { recipe_with_match_metadata }
      let(:search_result) do
        RecipeSearchResult.new(
          recipes: [recipe],
          ingredients: normalized_ingredients,
          page: 1,
          total_count: 1
        )
      end

      before do
        allow(RecipeMatcher).to receive(:call)
          .with(ingredients: normalized_ingredients, page: nil)
          .and_return(search_result)
      end

      it "returns success" do
        perform_request

        expect(response).to have_http_status(:ok)
      end

      it "calls RecipeMatcher with normalized ingredients" do
        perform_request

        expect(RecipeMatcher).to have_received(:call)
          .with(ingredients: normalized_ingredients, page: nil)
      end

      it "renders returned recipes" do
        perform_request

        expect(response.body).to include("1 recipe found")
        expect(response.body).to include("Chicken Tomato Pasta")
        expect(response.body).to include("80% ingredient match")
        expect(response.body).to include("Matched search ingredients:")
        expect(response.body).to include("chicken, tomato")
      end

      it "links recipe cards to the recipe show page" do
        perform_request

        expect(response.body).to include("recipe-card-link")
        expect(response.body).to include(recipe_path(recipe.id))
        expect(response.body).to include("ingredients%5B%5D=chicken")
        expect(response.body).to include("ingredients%5B%5D=tomato")
      end

      it "does not render pagination for a single page of results" do
        perform_request

        expect(response.body).not_to include('aria-label="Pagination"')
      end
    end

    context "with an ingredient shorter than the minimum length" do
      it "does not search and explains the input requirement" do
        expect(RecipeMatcher).not_to receive(:call)

        get search_path, params: { ingredients: ["c"] }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('minlength="3"')
        expect(response.body).to include(
          "Use at least 3 characters per ingredient."
        )
      end
    end

    context "with a low-coverage match in the recipe title" do
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

      it "renders the eligible recipe" do
        get search_path, params: { ingredients: ["garlic"] }

        expect(response.body).to include("Garlic Baby Potatoes")
        expect(response.body).to include("17% ingredient match")
        expect(response.body).to include("You may still need:")
        expect(response.body).to include("baby potatoes")
        expect(response.body).to include("olive oil")
        expect(response.body).to include("rosemary")
        expect(response.body).to include("Show 2 more")
        expect(response.body).to include("pepper")
        expect(response.body).to include("salt")
      end
    end

    context "when results span multiple pages" do
      let(:recipe) { recipe_with_match_metadata }
      let(:search_result) do
        RecipeSearchResult.new(
          recipes: [recipe],
          ingredients: %w[chicken tomato],
          page: 2,
          total_count: 25
        )
      end

      before do
        allow(RecipeMatcher).to receive(:call)
          .with(ingredients: %w[chicken tomato], page: "2")
          .and_return(search_result)
      end

      it "renders pagination links that preserve ingredients" do
        get search_path, params: { ingredients: %w[chicken tomato], page: 2 }

        expect(response.body).to include("25 recipes found")
        expect(response.body).to include('aria-label="Pagination"')
        expect(response.body).to include("Previous")
        expect(response.body).to include("Next")
        expect(response.body).to include("ingredients%5B%5D=chicken")
        expect(response.body).to include("ingredients%5B%5D=tomato")
        expect(response.body).to include("page=1")
        expect(response.body).to include("page=3")
      end

      it "renders numbered page links with the current page marked" do
        get search_path, params: { ingredients: %w[chicken tomato], page: 2 }

        expect(response.body).to include('aria-label="Page 1"')
        expect(response.body).to include('aria-label="Page 3"')
        expect(response.body).to include('aria-current="page"')
      end
    end

    context "when a non-empty search has no matches" do
      let(:search_result) do
        RecipeSearchResult.new(
          recipes: [],
          ingredients: ["garlic"],
          page: 1,
          total_count: 0
        )
      end

      before do
        allow(RecipeMatcher).to receive(:call)
          .with(ingredients: ["garlic"], page: nil)
          .and_return(search_result)
      end

      it "returns success" do
        get search_path, params: { ingredients: ["garlic"] }

        expect(response).to have_http_status(:ok)
      end

      it "renders the empty-results state" do
        get search_path, params: { ingredients: ["garlic"] }

        expect(response.body).to include("0 recipes found")
        expect(response.body).to include("No recipes matched those ingredients")
      end
    end

    context "when the requested page is beyond the search results" do
      let(:search_result) do
        RecipeSearchResult.new(
          recipes: [],
          ingredients: ["garlic"],
          page: 99,
          total_count: 25
        )
      end

      before do
        allow(RecipeMatcher).to receive(:call)
          .with(ingredients: ["garlic"], page: "99")
          .and_return(search_result)
      end

      it "renders the total without reporting that nothing matched" do
        get search_path, params: { ingredients: ["garlic"], page: 99 }

        expect(response.body).to include("25 recipes found")
        expect(response.body).to include("No recipes on this page")
        expect(response.body).not_to include("No recipes matched those ingredients")
      end
    end

    context "when search input exceeds the accepted bounds" do
      let(:accepted_ingredients) do
        (1..IngredientNormalizer::MAX_INGREDIENTS).map do |number|
          "ingredient-#{number}"
        end
      end

      let(:raw_ingredients) do
        accepted_ingredients + [
          "extra-ingredient",
          "x" * (IngredientNormalizer::MAX_INGREDIENT_LENGTH + 1)
        ]
      end

      let(:search_result) do
        RecipeSearchResult.new(
          recipes: [],
          ingredients: accepted_ingredients,
          page: 1,
          total_count: 0
        )
      end

      before do
        allow(RecipeMatcher).to receive(:call)
          .with(ingredients: accepted_ingredients, page: nil)
          .and_return(search_result)
      end

      it "passes only bounded ingredients to the matcher" do
        get search_path, params: { ingredients: raw_ingredients }

        expect(RecipeMatcher).to have_received(:call)
          .with(ingredients: accepted_ingredients, page: nil)
      end
    end
  end

  describe "GET /recipes/:id" do
    let!(:recipe) do
      create(
        :recipe,
        title: "Chicken Tomato Pasta",
        prep_time: 10,
        cook_time: 20,
        rating: 4.5,
        image_url: "https://example.com/pasta.jpg"
      )
    end

    before do
      create(:recipe_ingredient, recipe:, ingredient_text: "2 cups chicken stock")
      create(:recipe_ingredient, recipe:, ingredient_text: "1 tomato, diced")
      create(:recipe_ingredient, recipe:, ingredient_text: "1 onion")
      create(:recipe_ingredient, recipe:, ingredient_text: "salt")
      create(:recipe_ingredient, recipe:, ingredient_text: "pepper")
      create(:recipe_ingredient, recipe:, ingredient_text: "olive oil")
    end

    it "returns success" do
      get recipe_path(recipe)

      expect(response).to have_http_status(:ok)
    end

    it "renders the recipe details" do
      get recipe_path(recipe)

      expect(response.body).to include("Chicken Tomato Pasta")
      expect(response.body).to include("4.5")
      expect(response.body).to include("10 min")
      expect(response.body).to include("20 min")
      expect(response.body).to include("30 min")
      expect(response.body).to include("2 cups chicken stock")
      expect(response.body).to include("1 tomato, diced")
      expect(response.body).to include("https://example.com/pasta.jpg")
    end

    it "preserves search params on the back link" do
      get recipe_path(recipe, ingredients: %w[chicken tomato], page: 2)

      expect(response.body).to include("Back to search")
      expect(response.body).to include(search_path)
      expect(response.body).to include("ingredients%5B%5D=chicken")
      expect(response.body).to include("ingredients%5B%5D=tomato")
      expect(response.body).to include("page=2")
    end

    it "preserves browse params on the back link" do
      get recipe_path(recipe, category: "Dessert", rating: "4", page: 2)

      expect(response.body).to include("Back to browse")
      expect(response.body).to include(recipes_path)
      expect(response.body).to include("category=Dessert")
      expect(response.body).to include("rating=4")
      expect(response.body).to include("page=2")
    end

    it "renders search match details when ingredients are provided" do
      get recipe_path(recipe, ingredients: %w[chicken tomato garlic])

      expect(response.body).to include("33% ingredient match")
      expect(response.body).to include("Matched search ingredients:")
      expect(response.body).to include("chicken, tomato")
      expect(response.body).to include("Unused search ingredients:")
      expect(response.body).to include("garlic")
      expect(response.body).to include("You may still need")
      expect(response.body).to include("1 onion")
      expect(response.body).to include("salt")
      expect(response.body).to include("pepper")
      expect(response.body).to include("Show 1 more")
      expect(response.body).to include("olive oil")
    end

    it "does not render missing recipe ingredients when the search covers every ingredient" do
      get recipe_path(
        recipe,
        ingredients: %w[chicken tomato onion salt pepper olive]
      )

      expect(response.body).not_to include("You may still need")
    end

    it "does not render search match details without ingredients" do
      get recipe_path(recipe)

      expect(response.body).not_to include("Ingredient match:")
      expect(response.body).not_to include("Matched search ingredients:")
      expect(response.body).not_to include("Unused search ingredients:")
      expect(response.body).not_to include("You may still need")
    end
  end

  describe "GET /recipes" do
    let!(:dessert) do
      create(:recipe, title: "Chocolate Cake", category: "Dessert", rating: 4.8)
    end
    let!(:main) do
      create(:recipe, title: "Tomato Pasta", category: "Main", rating: 3.2)
    end
    let!(:salad) do
      create(:recipe, title: "Green Salad", category: "Salad", rating: 2.5)
    end

    before do
      create(:recipe_ingredient, recipe: dessert, ingredient_text: "2 cups flour")
      create(:recipe_ingredient, recipe: dessert, ingredient_text: "1 cup sugar")
    end

    it "returns success" do
      get recipes_path

      expect(response).to have_http_status(:ok)
    end

    it "renders recipes" do
      get recipes_path

      expect(response.body).to include("Chocolate Cake")
      expect(response.body).to include("Tomato Pasta")
      expect(response.body).to include("Green Salad")
    end

    it "renders rating and ingredients on recipe cards" do
      get recipes_path

      expect(response.body).to include("Rating")
      expect(response.body).to include("4.8")
      expect(response.body).to include("Ingredients")
      expect(response.body).to include("2 cups flour")
      expect(response.body).to include("1 cup sugar")
    end

    it "renders filter controls" do
      get recipes_path

      expect(response.body).to include("All categories")
      expect(response.body).to include("Dessert")
      expect(response.body).to include("Main")
      expect(response.body).to include("Salad")
      expect(response.body).to include("Any rating")
      expect(response.body).to include("5+")
      expect(response.body).to include("4+")
      expect(response.body).to include("3+")
    end

    it "filters by category" do
      get recipes_path, params: { category: "Dessert" }

      expect(response.body).to include("Chocolate Cake")
      expect(response.body).not_to include("Tomato Pasta")
      expect(response.body).not_to include("Green Salad")
    end

    it "filters by minimum rating" do
      get recipes_path, params: { rating: "4" }

      expect(response.body).to include("Chocolate Cake")
      expect(response.body).not_to include("Tomato Pasta")
      expect(response.body).not_to include("Green Salad")
    end

    it "ignores an invalid rating filter" do
      create(:recipe, title: "Unrated Soup", rating: nil)

      get recipes_path, params: { rating: "invalid" }

      expect(response.body).to include("Chocolate Cake")
      expect(response.body).to include("Unrated Soup")
      expect(response.body).not_to include(">Clear<")
    end

    it "renders a clear link when filters are active" do
      get recipes_path, params: { category: "Dessert", rating: "4" }

      expect(response.body).to include("Clear")
      expect(response.body).to include(%(href="#{recipes_path}"))
    end

    it "does not render a clear link without filters" do
      get recipes_path

      expect(response.body).not_to include(">Clear<")
    end

    context "when results span multiple pages" do
      before do
        create_list(:recipe, 12, category: "Dessert", rating: 4.5)
      end

      it "preserves active filters in pagination links" do
        get recipes_path, params: { category: "Dessert", rating: "4", page: 1 }

        expect(response.body).to include('aria-label="Pagination"')
        expect(response.body).to include("category=Dessert")
        expect(response.body).to include("rating=4")
        expect(response.body).to include("page=2")
        expect(response.body).to include('aria-label="Page 2"')
        expect(response.body).to include('aria-current="page"')
      end
    end

    context "when equal-rated recipes span multiple pages" do
      let!(:ordered_recipes) do
        (1..13).map do |number|
          create(
            :recipe,
            title: format("Stable Recipe %02d", number),
            category: "Stable",
            rating: 4.0
          )
        end
      end

      let!(:first_duplicate) do
        create(:recipe, title: "Stable Recipe Duplicate", category: "Stable", rating: 4.0)
      end

      let!(:second_duplicate) do
        create(:recipe, title: "Stable Recipe Duplicate", category: "Stable", rating: 4.0)
      end

      it "orders by title and id across pages" do
        duplicates_by_id = [first_duplicate, second_duplicate].sort_by(&:id)
        expected_second_page = [ordered_recipes.last, *duplicates_by_id]

        get recipes_path, params: { category: "Stable", page: 1 }
        first_page = Nokogiri::HTML(response.body)

        get recipes_path, params: { category: "Stable", page: 2 }
        second_page = Nokogiri::HTML(response.body)

        first_page_titles = first_page.css(".recipe-card-title").map(&:text)
        second_page_links = second_page.css(".recipe-card-link")

        expect(first_page_titles).to eq(ordered_recipes.first(12).map(&:title))
        expect(second_page_links.map { |link| link["aria-label"] }).to eq(
          expected_second_page.map(&:title)
        )
        expect(second_page_links.map { |link| link["href"] }).to eq(
          expected_second_page.map do |recipe|
            recipe_path(recipe, category: "Stable", page: 2)
          end
        )
      end
    end

    it "falls back to the first page for invalid page input" do
      get recipes_path, params: { page: "invalid" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Chocolate Cake")
    end

    it "caps huge page input without raising an error" do
      get recipes_path, params: { page: "99999999999999999999999999999" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No recipes matched those filters")
    end
  end

  def recipe_with_match_metadata
    recipe = build_stubbed(
      :recipe,
      title: "Chicken Tomato Pasta",
      prep_time: 10,
      cook_time: 20,
      rating: 4.5
    ).tap do |record|
      record.define_singleton_method(:coverage_ratio) { 0.8 }
      record.define_singleton_method(:total_time) { 30 }
      record.define_singleton_method(:matched_terms) { %w[chicken tomato] }
    end

    RecipeMatch.new(recipe:, search_ingredients: %w[chicken tomato])
  end
end
