Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  get "logout", to: "sessions#destroy", as: :destroy_session
  delete "logout", to: "sessions#destroy"
  # get "pages/home" # added by `rails g controler pages home`
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "pages#home"

  namespace :santander do
    resources :remessa_uploads, only: [ :new, :create ]
  end

  namespace :api do
      namespace :v1 do
        get "cobrancas/listar_cobrancas_cliente", to: "cobrancas#listar_cobrancas_cliente"
      end
  end


  namespace :bradesco do
    resources :remessa_uploads, only: [ :new, :create ]
  end
end
