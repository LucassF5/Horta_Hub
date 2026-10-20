class MembershipsController < ApplicationController
  before_action :set_membership, only: %i[edit update destroy reset_password]

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
      no_store
      render Views::Memberships::Credentials.new(
        membership: @creation.membership,
        password: @creation.generated_password,
        notice: "Funcionário adicionado com sucesso."
      )
    end
  end

  def edit
    authorize! @membership

    render Views::Memberships::Edit.new(membership: @membership)
  end

  def update
    # O cargo novo vai para o registro antes do authorize!: a policy confere o cargo atual e o novo.
    @membership.role = params.expect(membership: [ :role ])[:role]
    authorize! @membership

    if @membership.save
      redirect_to memberships_path, notice: "Cargo atualizado com sucesso."
    else
      render Views::Memberships::Edit.new(membership: @membership), status: :unprocessable_entity
    end
  end

  def destroy
    authorize! @membership

    user = @membership.user
    if @membership.destroy
      user.sessions.destroy_all unless user.member_of_active_organization?
      redirect_to memberships_path, notice: "Funcionário removido da organização.", status: :see_other
    else
      redirect_to memberships_path, alert: @membership.errors.full_messages.to_sentence, status: :see_other
    end
  end

  def reset_password
    authorize! @membership

    password = @membership.user.reset_password!
    no_store
    render Views::Memberships::Credentials.new(
      membership: @membership,
      password: password,
      notice: "Nova senha gerada com sucesso."
    )
  end

  private

  def set_membership
    @membership = Current.organization.memberships.includes(:user).find(params[:id])
  end

  def member_params
    params.expect(member: [ :username, :email_address, :role ])
  end
end
