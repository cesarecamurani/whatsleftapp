# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecipeImporter, type: :service do
  describe ".call" do
    subject(:result) { described_class.call(path: json_path) }

    let(:valid_recipe) do
      {
        "title" => "Golden Sweet Cornbread",
        "prep_time" => 10,
        "cook_time" => 25,
        "ingredients" => ["1 cup flour", "1 egg"],
        "ratings" => 4.74,
        "category" => "Cornbread",
        "image" => "https://example.com/cornbread.jpg"
      }
    end

    let(:recipes) { [valid_recipe] }
    let(:json_content) { recipes.to_json }
    let(:recipe) { Recipe.find_by!(title: valid_recipe["title"]) }

    let(:recipes_count) { 1 }
    let(:ingredients_count) { 2 }
    let(:skipped_recipes) { [] }

    let(:expected_result) do
      {
        recipes_count:,
        ingredients_count:,
        skipped_recipes: skipped_recipes
      }
    end

    let(:json_path) do
      file = Tempfile.new(["recipes", ".json"])
      file.write(json_content)
      file.close
      file.path
    end

    after do
      File.delete(json_path) if File.file?(json_path)
    end

    context "when the file does not exist" do
      let(:json_path) { "/nonexistent/recipes.json" }

      it "raises an ArgumentError" do
        expect { result }.to raise_error(ArgumentError, /File not found/)
      end
    end

    context "when the file contains invalid JSON" do
      let(:json_content) { "{ not valid json" }

      it "raises an ArgumentError" do
        expect { result }.to raise_error(ArgumentError, /Invalid JSON file/)
      end
    end

    context "when the JSON root is not an array" do
      let(:json_content) { {}.to_json }

      it "raises an ArgumentError" do
        expect { result }.to raise_error(ArgumentError, "Expected JSON root to be an array")
      end
    end

    context "when the file contains an empty array" do
      let(:recipes) { [] }
      let(:recipes_count) { 0 }
      let(:ingredients_count) { 0 }

      it "returns an empty import result" do
        expect(result).to eq(expected_result)
      end

      it "leaves the database empty" do
        result

        aggregate_failures do
          expect(Recipe.count).to eq(0)
          expect(RecipeIngredient.count).to eq(0)
        end
      end
    end

    context "when importing a valid recipe" do
      it "returns the import summary" do
        expect(result).to eq(expected_result)
      end

      it "persists the mapped recipe attributes" do
        result

        aggregate_failures do
          expect(recipe.prep_time).to eq(10)
          expect(recipe.cook_time).to eq(25)
          expect(recipe.rating).to eq(4.74)
          expect(recipe.category).to eq("Cornbread")
          expect(recipe.image_url).to eq("https://example.com/cornbread.jpg")
        end
      end

      it "links the ingredients to the recipe" do
        result

        expect(recipe.recipe_ingredients.pluck(:ingredient_text)).to eq(["1 cup flour", "1 egg"])
      end
    end

    context "when optional attributes are blank or missing" do
      let(:recipes) do
        [valid_recipe.merge("category" => "", "image" => "")]
      end

      it "stores them as nil" do
        result

        aggregate_failures do
          expect(recipe.category).to be_nil
          expect(recipe.image_url).to be_nil
        end
      end
    end

    context "when a category contains HTML entities" do
      let(:recipes) do
        [valid_recipe.merge("category" => "Country Crock&reg;")]
      end

      it "stores the decoded category value" do
        result

        expect(recipe.category).to eq("Country Crock®")
      end
    end

    context "when a recipe has no ingredients" do
      let(:recipes) { [valid_recipe.merge("ingredients" => [])] }
      let(:ingredients_count) { 0 }

      it "imports the recipe without ingredients" do
        expect(result).to eq(expected_result)
        expect(recipe.recipe_ingredients).to be_empty
      end
    end

    context "when ingredients contain blank values" do
      let(:recipes) do
        [
          valid_recipe.merge(
            "ingredients" => ["1 cup flour", "", "  ", nil]
          )
        ]
      end

      let(:ingredients_count) { 1 }

      it "imports only non-blank ingredients" do
        expect(result).to eq(expected_result)
        expect(recipe.recipe_ingredients.pluck(:ingredient_text)).to eq(["1 cup flour"])
      end
    end

    context "when ingredients contain duplicates or formatting differences" do
      let(:recipes) do
        [
          valid_recipe.merge(
            "ingredients" => [
              " Fresh Garlic ",
              "fresh garlic",
              "Salt",
              "salt"
            ]
          )
        ]
      end

      let(:ingredients_count) { 2 }

      it "normalizes and deduplicates ingredients before importing" do
        expect(result).to eq(expected_result)

        expect(recipe.recipe_ingredients.pluck(:ingredient_text))
          .to contain_exactly(
            "fresh garlic",
            "salt"
          )
      end
    end

    context "when importing multiple recipes" do
      let(:second_recipe_data) do
        valid_recipe.merge(
          "title" => "Second Recipe",
          "ingredients" => ["2 cups sugar"]
        )
      end

      let(:recipes) { [valid_recipe, second_recipe_data] }
      let(:second_recipe) { Recipe.find_by!(title: second_recipe_data["title"]) }
      let(:uuid_pattern) { /\A[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\z/ }

      it "links each ingredient to the correct recipe" do
        result

        aggregate_failures do
          expect(recipe.id).to match(uuid_pattern)
          expect(second_recipe.id).to match(uuid_pattern)
          expect(recipe.id).not_to eq(second_recipe.id)
          expect(recipe.recipe_ingredients.pluck(:ingredient_text)).to eq(["1 cup flour", "1 egg"])
          expect(second_recipe.recipe_ingredients.pluck(:ingredient_text)).to eq(["2 cups sugar"])
        end
      end
    end

    context "when a record is not an object" do
      let(:recipes) { [valid_recipe, "invalid"] }

      let(:skipped_recipes) do
        [
          {
            index: 1,
            title: nil,
            reason: "record is not an object"
          }
        ]
      end

      it "skips the record with its index and reason" do
        expect(result).to eq(expected_result)
      end
    end

    context "when a recipe title is blank" do
      let(:recipes) do
        [
          {
            "title" => "   ",
            "ingredients" => []
          }
        ]
      end

      let(:recipes_count) { 0 }
      let(:ingredients_count) { 0 }

      let(:skipped_recipes) do
        [
          {
            index: 0,
            title: "   ",
            reason: "title is missing"
          }
        ]
      end

      it "skips the recipe" do
        expect(result).to eq(expected_result)
      end
    end

    context "when ingredients are not an array" do
      let(:recipes) do
        [
          {
            "title" => "Invalid Recipe",
            "ingredients" => nil
          }
        ]
      end

      let(:recipes_count) { 0 }
      let(:ingredients_count) { 0 }

      let(:skipped_recipes) do
        [
          {
            index: 0,
            title: "Invalid Recipe",
            reason: "ingredients must be an array"
          }
        ]
      end

      it "skips the recipe" do
        expect(result).to eq(expected_result)
      end
    end

    context "when the file contains valid and invalid records" do
      let(:second_valid_recipe) do
        valid_recipe.merge(
          "title" => "Second Valid Recipe",
          "ingredients" => ["salt"]
        )
      end

      let(:recipes) { [valid_recipe, "invalid", second_valid_recipe] }
      let(:recipes_count) { 2 }
      let(:ingredients_count) { 3 }

      let(:skipped_recipes) do
        [
          {
            index: 1,
            title: nil,
            reason: "record is not an object"
          }
        ]
      end

      it "imports valid recipes and reports skipped records" do
        expect(result).to eq(expected_result)
      end
    end

    context "when replacing existing data" do
      let!(:existing_recipe) { create(:recipe, title: "Old Recipe") }

      let!(:existing_ingredient) do
        create(:recipe_ingredient, recipe: existing_recipe)
      end

      it "replaces the existing dataset" do
        result

        aggregate_failures do
          expect(Recipe.pluck(:title)).to eq(["Golden Sweet Cornbread"])
          expect(RecipeIngredient.exists?(existing_ingredient.id)).to be(false)
        end
      end
    end

    context "when the import fails inside the transaction" do
      let!(:existing_recipe) { create(:recipe, title: "Old Recipe") }

      let!(:existing_ingredient) do
        create(:recipe_ingredient, recipe: existing_recipe)
      end

      before do
        allow(Recipe).to receive(:insert_all!)
          .and_raise(ActiveRecord::StatementInvalid, "insert failed")
      end

      it "raises the error and rolls back the deletion" do
        expect { result }.to raise_error(ActiveRecord::StatementInvalid, "insert failed")

        aggregate_failures do
          expect(Recipe.exists?(existing_recipe.id)).to be(true)
          expect(RecipeIngredient.exists?(existing_ingredient.id)).to be(true)
        end
      end
    end

    context "when ingredients exceed the batch size" do
      before do
        stub_const("RecipeImporter::BATCH_SIZE", 2)
      end

      let(:recipes) do
        [
          valid_recipe.merge(
            "ingredients" => ["1 cup flour", "1 egg", "1 cup milk"]
          )
        ]
      end

      let(:ingredients_count) { 3 }

      it "imports the full batch and the remaining rows" do
        expect(result).to eq(expected_result)

        expect(recipe.recipe_ingredients.pluck(:ingredient_text)).to eq(
          ["1 cup flour", "1 egg", "1 cup milk"]
        )
      end
    end
  end
end
