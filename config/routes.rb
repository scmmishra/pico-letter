Rails.application.routes.draw do
  namespace :auth do
    get "login", to: "sessions#new"
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy"
  end

  # redirect /login to /auth/login
  get "/login", to: redirect("/auth/login")

  scope "/:slug" do
    resources :posts, only: [ :index ], path: "", module: "newsletters" do
      collection do
        get :archive
        get :drafts
      end
    end
  end

  get "/:slug", to: "newsletters#show", as: :newsletter

  root "newsletters#index"

  get "up" => "rails/health#show", as: :rails_health_check
end
