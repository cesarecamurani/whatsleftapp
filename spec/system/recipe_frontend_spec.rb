# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Recipe frontend", type: :system do
  before do
    driven_by(:selenium, using: :headless_chrome, screen_size: [1_400, 1_000])
  end

  it "updates and clears ingredient input state" do
    visit search_path

    expect(page).not_to have_button("Clear")

    fill_in "Ingredients", with: "Chicken"

    expect(page).to have_button("Clear")

    find("#ingredient-input").send_keys(:enter)

    expect(page).to have_css(".chip", text: "chicken")

    click_button "Clear"

    expect(page).to have_current_path(search_path)
    expect(page).not_to have_css(".chip")
    expect(page).not_to have_button("Clear")
  end

  it "shows a placeholder when a recipe image fails to load" do
    create(
      :recipe,
      title: "Recipe With Missing Image",
      image_url: "http://127.0.0.1:9/missing.jpg"
    )

    visit recipes_path

    within(".recipe-card") do
      expect(page).to have_css(".image-frame--fallback")
      expect(page).to have_text("No image available")
      expect(page).not_to have_css(".recipe-card__image", visible: true)
    end
  end
end
