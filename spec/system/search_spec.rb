require "rails_helper"

RSpec.describe "検索画面（JavaScript あり）", type: :system do
  before do
    create(:facility, :saturday, name: "土曜もあいてる教室")
    create(:facility, name: "平日だけの教室")
  end

  it "React の絞り込みパネルでチェックするとすぐ結果が変わる" do
    visit root_path

    within("[data-react-island=SearchFilterPanel]") do
      expect(page).to have_css("form[role=search]")
      check "土曜に利用できる"
    end

    expect(page).to have_current_path(/open_saturday=1/)
    expect(page).to have_content("土曜もあいてる教室")
    expect(page).to have_no_content("平日だけの教室")
  end

  it "キーワードを入れて探せる" do
    visit root_path
    fill_in "キーワード", with: "平日だけ"
    click_on "この条件で探す"

    expect(page).to have_content("1件")
    expect(page).to have_content("平日だけの教室")
  end
end
