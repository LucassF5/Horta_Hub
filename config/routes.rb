Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resource :session
  resources :users, only: %i[ new create destroy ]
  resources :passwords, param: :token
  resources :products
  resources :clients
  resources :sales

  root "home#index"
end
