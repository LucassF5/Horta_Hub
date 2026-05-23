class UsersController < ApplicationController
  unauthenticated_access_only only: %i[ new create ]

  def new
    @user = User.new
  end

  def create
    @user = User.create(user_params)

    if @user.save
      redirect_to new_session_path, notice: "Conta criada com sucesso!"
    else
      redirect_to :new, status: :unprocessable_entity
    end
  end

  def destroy
    terminate_session
    Current.user.destroy
    redirect_to new_session_path, notice: "Conta excluída com sucesso."
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :username)
  end
end
