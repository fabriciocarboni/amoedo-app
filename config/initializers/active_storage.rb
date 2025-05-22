# config/initializers/active_storage.rb
Rails.application.config.to_prepare do
  ActiveStorage::Blob.class_eval do
    def custom_url_for_direct_upload
      route_for(:custom_direct_upload, expires_in: ActiveStorage.urls_expire_in)
    end
  end
end
