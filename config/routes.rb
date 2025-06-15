Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  get "logout", to: "sessions#destroy", as: :destroy_session
  delete "logout", to: "sessions#destroy"

  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "pages#home"

  namespace :api do
      namespace :v1 do
        get "asaas/cobrancas/listar_cobrancas_cliente", to: "asaas_cobrancas#listar_cobrancas_cliente"
        get "santander/cobrancas/listar_cobrancas_cliente", to: "santander_cobrancas#listar_cobrancas_cliente"
        get "santander/cobrancas/listar_vencimentos", to: "santander_vencimentos#listar_vencimentos"
      end
  end

  namespace :santander do
    resources :remessa_uploads, only: [ :new, :create ]
  end

  namespace :bradesco do
    resources :remessa_uploads, only: [ :new, :create ]
  end

  # Custom Active Storage routes
  direct :custom_rails_blob do |blob, options|
    route_for(
      :download_file,
      blob.signed_id,
      blob.filename,
      options
    )
  end

  # Map the Active Storage routes to custom paths
  scope "/files" do
    get "/download/:signed_id/*filename", to: "active_storage/blobs/redirect#show", as: :download_file
    get "/representation/:signed_blob_id/:variation_key/*filename", to: "active_storage/representations/redirect#show", as: :representation_file
    get "/proxy/:signed_id/*filename", to: "active_storage/blobs/proxy#show", as: :proxy_file
  end

  # Short URL route with format support
  get "dl/:token", to: "downloads#show", as: :short_download
  get "dl/:token.:format", to: "downloads#show"
end
