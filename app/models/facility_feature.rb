class FacilityFeature < ApplicationRecord
  belongs_to :facility
  belongs_to :feature

  validates :feature_id, uniqueness: { scope: :facility_id }
end
