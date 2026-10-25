# 支援内容のタグ。一覧は db/seeds.rb で投入する
class Feature < ApplicationRecord
  has_many :facility_features, dependent: :destroy
  has_many :facilities, through: :facility_features

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true

  scope :ordered, -> { order(:position, :id) }
end
