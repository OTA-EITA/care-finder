class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorite_facilities, through: :favorites, source: :facility
  has_many :facility_memberships, dependent: :destroy
  has_many :managed_facilities, through: :facility_memberships, source: :facility

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 12 }, allow_nil: true

  def favorited?(facility)
    favorites.exists?(facility_id: facility.id)
  end

  def staff?
    facility_memberships.exists?
  end
end
