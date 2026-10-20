class UsersController < ApplicationController
  def destroy
    if Current.user.destroy
      terminate_session
      redirect_to new_session_path, notice: "Conta excluída com sucesso."
    else
      redirect_to root_path, alert: "Você é o único dono de uma organização; transfira a posse antes de excluir a conta."
    end
  end
end
