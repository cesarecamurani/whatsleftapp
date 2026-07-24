# frozen_string_literal: true

FactoryBot.define do
  factory :recipe do
    title { "Existing Recipe" }
    prep_time { 10 }
    cook_time { 20 }
    rating { 4.5 }
    category { "Main" }
    image_url { "https://example.com/recipe.jpg" }
  end
end
