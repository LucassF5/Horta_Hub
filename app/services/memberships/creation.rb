# frozen_string_literal: true

module Memberships
  # Adiciona um membro à organização: vincula uma conta existente pelo e-mail
  # ou cria uma conta nova com senha gerada, exibida uma única vez.
  class Creation
    include ActiveModel::Model
    include ActiveModel::Attributes

    ALREADY_MEMBER_MESSAGE = "já pertence a esta organização"
    FORM_ATTRIBUTES = %i[username email_address role].freeze

    attribute :username, :string
    attribute :email_address, :string
    attribute :role, :string, default: "viewer"

    attr_reader :organization, :generated_password

    def self.model_name
      @model_name ||= ActiveModel::Name.new(self, nil, "Member")
    end

    def initialize(organization:, **attributes)
      @organization = organization
      super(**attributes)
    end

    def membership
      @membership ||= organization.memberships.build(role: role)
    end

    def existing_user?
      existing_user.present?
    end

    def save
      errors.clear
      existing_user? ? add_existing_user : create_user_with_membership
    end

    private

    def existing_user
      return @existing_user if defined?(@existing_user)

      @existing_user = User.find_by(email_address: email_address)
    end

    def add_existing_user
      if organization.memberships.exists?(user: existing_user)
        errors.add(:email_address, ALREADY_MEMBER_MESSAGE)
        return false
      end

      membership.user = existing_user
      return true if membership.save

      copy_errors_from(membership)
      false
    end

    def create_user_with_membership
      password = User.generate_password
      user = User.new(username: username, email_address: email_address, password: password)
      membership.user = user

      ActiveRecord::Base.transaction do
        raise ActiveRecord::Rollback unless user.save && membership.save

        @generated_password = password
      end
      return true if generated_password

      membership.validate if membership.errors.empty?
      copy_errors_from(user, membership)
      false
    end

    def copy_errors_from(*records)
      records.each do |record|
        record.errors.each do |error|
          attribute = error.attribute.in?(FORM_ATTRIBUTES) ? error.attribute : :base
          errors.add(attribute, error.message)
        end
      end
    end
  end
end
