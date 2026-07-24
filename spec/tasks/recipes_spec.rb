# frozen_string_literal: true

require "rails_helper"
require "rake"

RSpec.describe "recipes:import" do
  subject(:task) { Rake::Task["recipes:import"] }

  let(:dataset_path) { Rails.root.join("data/recipes.json") }

  let(:import_result) do
    {
      recipes_count: 2,
      ingredients_count: 3,
      skipped_recipes: []
    }
  end

  before do
    Rails.application.load_tasks unless Rake::Task.task_defined?("recipes:import")

    task.reenable

    allow(RecipeImporter).to receive(:call).and_return(import_result)
  end

  it "imports recipes from the dataset" do
    task.invoke

    expect(RecipeImporter).to have_received(:call).with(path: dataset_path)
  end

  it "prints the import summary" do
    expected_output = <<~OUTPUT
      Recipes imported: 2
      Ingredients imported: 3
      Recipes skipped: 0
    OUTPUT

    expect { task.invoke }.to output(expected_output).to_stdout
  end

  context "when recipes are skipped" do
    let(:skipped_recipes) do
      [
        {
          index: 1,
          title: nil,
          reason: "title is missing"
        },
        {
          index: 4,
          title: "Invalid Recipe",
          reason: "ingredients must be an array"
        }
      ]
    end

    let(:import_result) do
      {
        recipes_count: 2,
        ingredients_count: 3,
        skipped_recipes:
      }
    end

    it "prints the skipped recipe details" do
      expected_output = <<~OUTPUT
        Recipes imported: 2
        Ingredients imported: 3
        Recipes skipped: 2

        Skipped recipes:
        - (no title): title is missing
        - Invalid Recipe: ingredients must be an array
      OUTPUT

      expect { task.invoke }.to output(expected_output).to_stdout
    end
  end

  context "when the importer fails" do
    before do
      allow(RecipeImporter).to receive(:call)
        .and_raise(ArgumentError, "File not found")
    end

    it "propagates the error" do
      expect { task.invoke }.to raise_error(ArgumentError, "File not found")
    end
  end
end

RSpec.describe "recipes:resolve_image_urls" do
  subject(:task) { Rake::Task["recipes:resolve_image_urls"] }

  let!(:resolvable_recipe) do
    create(:recipe, image_url: "https://imagesvc.meredithcorp.io/proxy")
  end

  let!(:unchanged_recipe) do
    create(:recipe, image_url: "https://example.com/b.jpg")
  end

  before do
    Rails.application.load_tasks unless Rake::Task.task_defined?("recipes:resolve_image_urls")

    task.reenable

    allow(RecipeImageUrlResolver).to receive(:call)
      .with(resolvable_recipe.image_url)
      .and_return("https://images.example.com/a.jpg")

    allow(RecipeImageUrlResolver).to receive(:call)
      .with(unchanged_recipe.image_url)
      .and_return(unchanged_recipe.image_url)
  end

  it "updates recipes whose resolved URL changed" do
    task.invoke

    expect(resolvable_recipe.reload.image_url).to eq("https://images.example.com/a.jpg")
  end

  it "leaves recipes whose resolved URL is unchanged" do
    task.invoke

    expect(unchanged_recipe.reload.image_url).to eq("https://example.com/b.jpg")
  end

  it "prints the number of updated recipes" do
    expect { task.invoke }.to output("Updated 1 recipe image URLs\n").to_stdout
  end
end
