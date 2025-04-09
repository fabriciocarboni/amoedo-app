# # app/controllers/concerns/api_authenticatable.rb
# module ApiAuthenticatable
#   extend ActiveSupport::Concern

#   included do
#     before_action :authenticate_api_key
#   end

#   private

#   def authenticate_api_key
#     bearer_token = request.headers["Authorization"]&.split(" ")&.last
#     api_key = ApiKey.find_by(access_token: bearer_token, active: true)
#     if api_key
#       @current_api_client = {
#         name: api_key.client_name,
#         email: api_key.email
#       }
#     else
#       render json: { error: "Unauthorized" }, status: :unauthorized
#     end
#   end
# end



# app/controllers/concerns/api_authenticatable.rb
module ApiAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_api_key
  end

  private

  def authenticate_api_key
    bearer_token = request.headers["Authorization"]&.split(" ")&.last
    api_key = ApiKey.find_by(access_token: bearer_token, active: true)
    if api_key
      @current_api_client = {
        name: api_key.client_name,
        email: api_key.email
      }
    else
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
end
