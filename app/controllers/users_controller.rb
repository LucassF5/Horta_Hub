class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]

  def new
    @user = User.new
  end

  def create
    @user = User.create!(user_params)

    if @user.save
      redirect_to new_session_path, notice: "Conta criada com sucesso!"
    else
      redirect_to :new, status: :unprocessable_entity
    end
  end

  def destroy
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :username)
  end
end
