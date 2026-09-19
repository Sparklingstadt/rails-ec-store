Rails.application.routes.draw do
  root "products#index"
  resource :registration, only: [ :new, :create ]
  resource :session, only: [ :new, :create, :destroy ]
  resource :account, only: [ :show, :update ]
  namespace :admin do
    resources :products, only: [ :index, :new, :create, :edit, :update ], param: :slug
    resources :orders, only: [ :index, :show, :update ], param: :number
  end
  resources :products, only: [ :index, :show ], param: :slug
  resource :cart, only: :show
  resources :cart_items, only: [ :create, :update, :destroy ]
  resources :favorites, only: [ :index, :create, :destroy ]
  resources :orders, only: [ :index, :new, :create, :show ], param: :number do
    post :cancel, on: :member
  end
  get "about", to: "pages#about"
  get "guide", to: "pages#guide"
  get "up" => "rails/health#show", as: :rails_health_check
end
