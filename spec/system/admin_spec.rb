require "rails_helper"

RSpec.describe "管理画面（JavaScript あり）", type: :system do
  let(:facility) { create(:facility, name: "担当の教室") }
  let(:staff) { create(:user, :staff, facility:) }

  before { create(:feature, name: "運動療育") }

  it "紹介文の残り文字数を表示し、保存すると公開ページに出る" do
    visit new_session_path
    fill_in "メールアドレス", with: staff.email_address
    fill_in "パスワード", with: "correct-horse-battery"
    within("main") { click_on "ログイン" }
    expect(page).to have_link("掲載情報の管理")

    visit edit_admin_facility_path(facility)
    fill_in "紹介文", with: "体を動かす活動が中心です"
    expect(page).to have_content("あと 1988 文字")
    choose "あり"
    check "運動療育"
    click_on "保存する"

    expect(page).to have_content("掲載情報を更新しました")
    visit facility_path(facility)
    expect(page).to have_content("体を動かす活動が中心です")
    expect(page).to have_content("送迎あり")
  end
end
