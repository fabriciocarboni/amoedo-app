class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: "Tente novamente mais tarde." }

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "Ops...Parece que seu email ou senha não são válidos."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, notice: "Logout efetuado com sucesso."
  end
end
