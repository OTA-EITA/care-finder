require "rails_helper"

RSpec.describe Favorite do
  it "同じ事業所を二重に登録できない" do
    favorite = create(:favorite)
    expect(build(:favorite, user: favorite.user, facility: favorite.facility)).not_to be_valid
  end
end
