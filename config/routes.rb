Rails.application.routes.draw do
  root "facilities#index"

  resources :facilities, only: %i[index show] do
    resource :favorite, only: %i[create destroy]
  end
  resources :favorites, only: :index

  resource :session, only: %i[new create destroy]
  resource :registration, only: %i[new create]
  resources :passwords, param: :token, only: %i[new create edit update]

  namespace :admin do
    resources :facilities, only: %i[index edit update]
  end

  get "about" => "pages#about", as: :about

  # ALB のヘルスチェック。アプリが起動して例外なく応答できれば 200
  get "up" => "rails/health#show", as: :rails_health_check
end
