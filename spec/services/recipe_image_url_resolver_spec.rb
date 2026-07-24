# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecipeImageUrlResolver, type: :service do
  describe ".call" do
    subject(:resolved_url) { described_class.call(url) }

    context "when the URL is blank" do
      let(:url) { "" }

      it "returns nil" do
        expect(resolved_url).to be_nil
      end
    end

    context "when the URL is not a Meredith proxy URL" do
      let(:url) { "https://example.com/recipe.jpg" }

      it "returns the URL unchanged" do
        expect(resolved_url).to eq(url)
      end
    end

    context "when the URL is a Meredith proxy URL" do
      let(:embedded_url) { "https://images.media-allrecipes.com/userphotos/9443508.jpg" }
      let(:url) do
        "https://imagesvc.meredithcorp.io/v3/mm/image?url=#{URI.encode_www_form_component(embedded_url)}"
      end

      it "returns the embedded source URL" do
        expect(resolved_url).to eq(embedded_url)
      end
    end

    context "when a Meredith proxy URL has no query string" do
      let(:url) { "https://imagesvc.meredithcorp.io/v3/mm/image" }

      it "returns the URL unchanged" do
        expect(resolved_url).to eq(url)
      end
    end

    context "when a Meredith proxy URL is missing the embedded url param" do
      let(:url) { "https://imagesvc.meredithcorp.io/v3/mm/image?w=200&q=60" }

      it "returns the URL unchanged" do
        expect(resolved_url).to eq(url)
      end
    end

    context "when the URL cannot be parsed" do
      let(:url) { "https://example.com/a b.jpg" }

      it "returns the URL unchanged" do
        expect(resolved_url).to eq(url)
      end
    end
  end
end
