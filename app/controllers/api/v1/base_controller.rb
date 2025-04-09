# # app/controllers/api/v1/base_controller.rb
# module Api
#   module V1
#     class BaseController < ApplicationController
#       include ApiAuthenticatable
#     end
#   end
# end


# app/controllers/api/v1/base_controller.rb
# app/controllers/api/v1/base_controller.rb
module Api
  module V1
    class BaseController < ApiController
      include ApiAuthenticatable

      # No need for layout false or set_json_format here
      # ActionController::API doesn't use layouts and always responds with JSON by default
    end
  end
end
