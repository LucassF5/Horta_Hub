Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resource :session
  resource :current_organization, only: %i[ update ]
  resources :users, only: %i[ destroy ]
  resources :passwords, param: :token
  resources :organizations, only: %i[ new create ]
  resources :import_batches, only: %i[ index show new create ] do
    get :progress, on: :member
  end
  resources :products, param: :slug
  resources :clients, param: :slug
  resources :memberships, only: %i[ index new create edit update destroy ] do
    post :reset_password, on: :member
  end
  resources :sales do
    collection do
      get :sale_item_fields
    end
  end

  root "home#index"
end
