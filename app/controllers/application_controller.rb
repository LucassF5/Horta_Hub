class ApplicationController < ActionController::Base
  include Authentication

  allow_browser versions: :modern
  before_action :current_user

  def encode_token(payload)
    JWT.encode(payload, Rails.application.credentials.secret_key_base,  "HS256")
  end

  def decode_token(token)
    decode = JWT.decode(token, Rails.application.credentials.secret_key_base, true, { algorithm: "HS256" })
    decode[0]
  rescue JWT::DecodeError
    nil
  end

  private

  def authenticate_user!
    unless current_user
      redirect_to new_session_path, notice: "Please sign in to continue."
    end
  end

  def current_user
    token = cookies.signed[:jwt]
    return unless token

    decoded_token = decode_token(token)
    @current_user ||= User.find_by(id: decoded_token["user_id"]) if decoded_token
  end

  def set_jwt_cookie(token)
    cookies.signed[:jwt] ={
      value: token,
      httponly: true,
      secure: Rails.env.production?,
      same_site: :strict
    }
  end
end
