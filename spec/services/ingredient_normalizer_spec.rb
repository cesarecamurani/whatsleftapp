# frozen_string_literal: true

require "rails_helper"

RSpec.describe IngredientNormalizer, type: :service do
  describe ".call" do
    subject(:normalized) { described_class.call(values) }

    context "when values are nil" do
      let(:values) { nil }

      it "returns an empty array" do
        expect(normalized).to eq([])
      end
    end

    context "when a single string is given" do
      let(:values) { " Chicken " }

      it "wraps, trims, and downcases the value" do
        expect(normalized).to eq(["chicken"])
      end
    end

    context "when values contain blanks and nils" do
      let(:values) { ["chicken", "", "   ", nil] }

      it "removes blank and nil values" do
        expect(normalized).to eq(["chicken"])
      end
    end

    context "when values differ only by case and whitespace" do
      let(:values) { [" Chicken ", "TOMATO", "chicken"] }

      it "deduplicates after normalization, preserving first-seen order" do
        expect(normalized).to eq(%w[chicken tomato])
      end
    end

    context "when a value is shorter than the minimum length" do
      let(:values) { ["a" * (described_class::MIN_INGREDIENT_LENGTH - 1)] }

      it "rejects the value" do
        expect(normalized).to be_empty
      end
    end

    context "when a value is exactly the minimum length" do
      let(:values) { ["a" * described_class::MIN_INGREDIENT_LENGTH] }

      it "keeps the boundary value" do
        expect(normalized).to eq(["a" * described_class::MIN_INGREDIENT_LENGTH])
      end
    end

    context "when a value is exactly the maximum length" do
      let(:values) { ["a" * described_class::MAX_INGREDIENT_LENGTH] }

      it "keeps the boundary value" do
        expect(normalized).to eq(["a" * described_class::MAX_INGREDIENT_LENGTH])
      end
    end

    context "when a value exceeds the maximum length" do
      let(:values) { ["a" * (described_class::MAX_INGREDIENT_LENGTH + 1)] }

      it "rejects the value" do
        expect(normalized).to be_empty
      end
    end

    context "when more than the maximum number of ingredients are given" do
      let(:values) do
        (1..(described_class::MAX_INGREDIENTS + 5)).map { |number| "ingredient-#{number}" }
      end

      it "keeps only the maximum number of ingredients" do
        expect(normalized.size).to eq(described_class::MAX_INGREDIENTS)
      end
    end
  end
end
