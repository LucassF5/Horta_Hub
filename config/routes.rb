Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resource :session
  resource :current_organization, only: %i[ update ]
  resources :users, only: %i[ destroy ]
  resources :passwords, param: :token
  resources :organizations, only: %i[ new create ]
  resources :products
  resources :clients
  resources :sales

  root "home#index"
end
