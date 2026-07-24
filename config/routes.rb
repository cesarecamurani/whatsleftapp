Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "recipes#index"
  get "search", to: "recipes#index", as: :search
  get "recipes", to: "recipes#index", as: :recipes

  resources :recipes, only: [:show]
end
