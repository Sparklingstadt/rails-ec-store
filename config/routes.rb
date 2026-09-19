Rails.application.routes.draw do
  root "products#index"
  resources :products, only: [ :index, :show ], param: :slug
  resource :cart, only: :show
  resources :cart_items, only: [ :create, :update, :destroy ]
  resources :favorites, only: [ :index, :create, :destroy ]
  resources :orders, only: [ :index, :new, :create, :show ], param: :number
  get "about", to: "pages#about"
  get "guide", to: "pages#guide"
  get "up" => "rails/health#show", as: :rails_health_check
end
