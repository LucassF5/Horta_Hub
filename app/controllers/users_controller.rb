class UsersController < ApplicationController
  def destroy
    terminate_session
    Current.user.destroy
    redirect_to new_session_path, notice: "Conta excluída com sucesso."
  end
end
