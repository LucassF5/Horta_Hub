class Organization < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :products, dependent: :restrict_with_error
  has_many :clients, dependent: :restrict_with_error

  enum :status, { active: "active", inactive: "inactive" }

  validates :name, presence: true, length: { maximum: 100 }
  validates :slug, presence: true,
                   uniqueness: true,
                   format: { with: /\A[a-z0-9\-]+\z/, message: "only lowercase letters, numbers and hyphens" }
  validates :status, presence: true

  before_validation :generate_slug, on: :create, if: -> { slug.blank? }

  def membership_for(user)
    memberships.find_by(user: user)
  end

  private

  def generate_slug
    self.slug = name.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|-\z/, "")
  end
end

# == Schema Information
#
# Table name: organizations
#
#  id         :integer          not null, primary key
#  name       :string(100)      not null
#  slug       :string           not null
#  status     :string           default("active"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_organizations_on_slug  (slug) UNIQUE
#
