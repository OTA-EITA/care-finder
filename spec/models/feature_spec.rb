require "rails_helper"

RSpec.describe Feature do
  it "コードは重複できない" do
    create(:feature, code: "exercise")
    expect(build(:feature, code: "exercise")).not_to be_valid
  end

  it "表示順に並ぶ" do
    b = create(:feature, position: 2)
    a = create(:feature, position: 1)
    expect(described_class.ordered).to eq([ a, b ])
  end
end
