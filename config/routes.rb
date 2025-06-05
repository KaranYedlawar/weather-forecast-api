Rails.application.routes.draw do
  # get "up" => "rails/health#show", as: :rails_health_check

  root to: 'weather/forecasts#new'

  namespace :weather do
    resources :forecasts, only: [:new, :create]
  end
end
