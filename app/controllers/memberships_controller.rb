class MembershipsController < ApplicationController
  def index
    authorize!

    memberships = Current.organization.memberships
      .includes(:user)
      .joins(:user)
      .in_order_of(:role, Membership::ROLES_BY_RANK.reverse)
      .order(User.arel_table[:username])
    render Views::Memberships::Index.new(memberships: memberships)
  end

  def new
    @creation = Memberships::Creation.new(organization: Current.organization)
    authorize! @creation.membership

    render Views::Memberships::New.new(creation: @creation)
  end

  def create
    @creation = Memberships::Creation.new(organization: Current.organization, **member_params.to_h.symbolize_keys)
    authorize! @creation.membership

    if !@creation.save
      render Views::Memberships::New.new(creation: @creation), status: :unprocessable_entity
    elsif @creation.existing_user?
      redirect_to memberships_path, notice: "Usuário já existente adicionado à organização."
    else
      response.headers["Cache-Control"] = "no-store"
      render Views::Memberships::Credentials.new(
        membership: @creation.membership,
        password: @creation.generated_password,
        notice: "Funcionário adicionado com sucesso."
      )
    end
  end

  private

  def member_params
    params.expect(member: [ :username, :email_address, :role ])
  end
end
