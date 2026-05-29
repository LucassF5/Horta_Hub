class OrganizationsController < ApplicationController
  unauthenticated_access_only only: %i[new create]

  def new
    @organization = Organization.new
    @user = User.new
  end

  def create
    @organization = Organization.new(organization_params)
    @user = User.new(user_params)

    ActiveRecord::Base.transaction do
      @user.save!
      @organization.save!
      @organization.memberships.create!(user: @user, role: :owner)
    end

    start_new_session_for @user
    redirect_to root_path, notice: "Organização criada com sucesso!"
  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = "Erro ao criar organização. Verifique os dados e tente novamente."
    render :new, status: :unprocessable_entity
  end

  private

  def organization_params
    params.expect(organization: [ :name ])
  end

  def user_params
    params.expect(user: [ :username, :email_address, :password ])
  end
end
