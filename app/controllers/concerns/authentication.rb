module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    before_action :set_current_organization
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end

    def unauthenticated_access_only(**options)
      allow_unauthenticated_access(**options)
      before_action -> { redirect_to root_url if authenticated? }, **options
    end
  end

  private
    def authenticated?
      resume_session
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      Current.session ||= find_session_by_cookie
    end

    def find_session_by_cookie
      Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to new_session_path
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_url
    end

    def current_user
      Current.user
    end

    def current_organization
      Current.organization
    end

    def set_current_organization
      return unless authenticated?

      Current.membership = current_membership
      Current.organization = Current.membership&.organization

      if Current.organization.nil?
        session.delete(:organization_id)
        redirect_to new_organization_path, alert: "Você precisa criar ou pertencer a uma organização."
      end
    end

    def current_membership
      selected_membership || default_membership
    end

    def selected_membership
      return if session[:organization_id].blank?

      Current.user
        .memberships
        .includes(:organization)
        .find_by(organization_id: session[:organization_id])
        &.then { |membership| membership.organization.active? ? membership : nil }
    end

    def default_membership
      Current.user
        .memberships
        .includes(:organization)
        .joins(:organization)
        .merge(Organization.active)
        .order(:created_at)
        .first
        &.tap { |membership| session[:organization_id] = membership.organization_id }
    end

    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }
      end
    end

    def terminate_session
      Current.session.destroy
      session.delete(:organization_id)
      cookies.delete(:session_id)
    end
end
