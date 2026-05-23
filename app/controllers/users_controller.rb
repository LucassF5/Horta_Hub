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
      flash.now[:alert] = "Erro ao criar conta. Verifique os dados e tente novamente."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    terminate_session
    Current.user.destroy
    redirect_to new_session_path, notice: "Conta excluída com sucesso."
  end

  private

  def user_params
    params.expect(user: [ :email_address, :password, :username ])
  end
end
