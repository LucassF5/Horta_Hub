class SessionsController < ApplicationController
  unauthenticated_access_only only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Tente novamente mais tarde." }

  def new
    render Views::Sessions::New.new(params: params)
  end

  def create
    user = User.find_by(email_address: params[:email_address])
    if user&.authenticate(params[:password])
      start_new_session_for user
      redirect_to after_authentication_url
    else
      flash.now[:alert] = "Email ou senha inválidos."
      render Views::Sessions::New.new(params: params), status: :unprocessable_entity
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other, notice: "Logout efetuado com sucesso."
  end
end
