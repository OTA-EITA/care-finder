require "rails_helper"

RSpec.describe "db/seeds.rb" do
  def load_seeds = expect { Rails.application.load_seed }.to output(/デモ用アカウント/).to_stdout

  it "何度実行しても同じ件数になり、サンプルは架空と分かる名前にする" do
    2.times { load_seeds }

    expect(Facility.where(source: "sample").count).to eq(7)
    expect(Facility.where(source: "sample").pluck(:name)).to all(include("（架空）"))
    expect(User.find_by!(email_address: "staff@example.com").managed_facilities.count).to eq(1)
  end
end
