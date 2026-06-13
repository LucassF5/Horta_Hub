class Client < ApplicationRecord
    extend FriendlyId

    belongs_to :organization
    has_many :sales, dependent: :restrict_with_error

    friendly_id :name, use: [ :slugged, :scoped, :history ], scope: :organization

    validates :name, presence: true, length: { minimum: 3, maximum: 30 }
    validates :client_type, presence: true
    validates :slug, presence: true, uniqueness: { scope: :organization_id }

    enum :client_type, {
        pessoa_fisica: "Pessoa Física",
        pessoa_juridica: "Pessoa Jurídica"
    }

    def should_generate_new_friendly_id?
        slug.blank? || (will_save_change_to_name? && !will_save_change_to_slug?)
    end
end

# == Schema Information
#
# Table name: clients
#
#  id              :integer          not null, primary key
#  client_type     :string           not null
#  name            :string(65)       not null
#  phone           :string
#  slug            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer          not null
#
# Indexes
#
#  index_clients_on_organization_id_and_slug  (organization_id,slug) UNIQUE
#
# Foreign Keys
#
#  organization_id  (organization_id => organizations.id)
#
