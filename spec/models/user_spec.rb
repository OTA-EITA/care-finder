require "rails_helper"

RSpec.describe User do
  it "メールアドレスは前後の空白を除き小文字にする" do
    expect(create(:user, email_address: " Foo@Example.COM ").email_address).to eq("foo@example.com")
  end

  it "メールアドレスは重複できない" do
    create(:user, email_address: "a@example.com")
    expect(build(:user, email_address: "A@example.com")).not_to be_valid
  end

  it "メールアドレスの形式を確かめる" do
    expect(build(:user, email_address: "not-an-email")).not_to be_valid
  end

  it "パスワードは 12 文字以上" do
    expect(build(:user, password: "short")).not_to be_valid
  end

  describe "#favorited?" do
    it "お気に入りに入れた事業所だけ true" do
      user = create(:user)
      facility = create(:facility)
      expect(user.favorited?(facility)).to be false
      create(:favorite, user:, facility:)
      expect(user.reload.favorited?(facility)).to be true
    end
  end

  describe "#staff?" do
    it "事業所に所属していれば true" do
      expect(create(:user)).not_to be_staff
      expect(create(:user, :staff)).to be_staff
    end
  end
end
