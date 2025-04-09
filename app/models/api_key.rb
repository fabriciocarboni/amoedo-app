# app/models/api_key.rb

# it must create a migration rails g migration CreateApiKeys
#
# To create an api key  run below in rails console
# ApiKey.create!(access_token: SecureRandom.hex(32), client_name: "Tigor", email: "tigor@tigor.ai", active: true)

# Every request rails check in the table api_key if the token matches and is active.

# This video shows how to generate authentication for fronend apps
# https://youtu.be/38m9Q_CM5vc?si=Tozm4UYyZUknY72l&t=187

class ApiKey < ApplicationRecord
  before_create :generate_access_token

  validates :client_name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :access_token, uniqueness: true

  private

  def generate_access_token
    self.access_token = SecureRandom.hex(32)
  end
end
