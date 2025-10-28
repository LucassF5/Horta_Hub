Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resource :session
  resource :user, only: %i[ new create destroy ]
  resources :passwords, param: :token

  root "home#index"
end
