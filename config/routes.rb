Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "pages#home"
  get "search", to: "recipes#index", as: :search
  get "recipes", to: "recipes#browse", as: :recipes

  resources :recipes, only: [:show]
end
