# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Pages", type: :request do
  describe "GET /" do
    it "returns success" do
      get root_path

      expect(response).to have_http_status(:ok)
    end

    it "renders both entry points" do
      get root_path

      expect(response.body).to include("Match recipes")
      expect(response.body).to include(search_path)
      expect(response.body).to include("Browse recipes")
      expect(response.body).to include(recipes_path)
    end
  end
end
