require "rails_helper"

RSpec.describe "お気に入り", type: :request do
  let(:user) { create(:user) }
  let(:facility) { create(:facility, name: "ひまわりクラブ") }

  it "ログインしていなければログイン画面へ送り、戻り先を事業所ページにする" do
    post facility_favorite_path(facility)

    expect(response).to redirect_to(new_session_path)
    sign_in_as(user)
    expect(response).to redirect_to(facility_url(facility))
  end

  it "追加して一覧に出し、外せる" do
    sign_in_as(user)

    post facility_favorite_path(facility), as: :turbo_stream
    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(user.favorite_facilities).to eq([ facility ])

    get favorites_path
    expect(response.body).to include("ひまわりクラブ")

    delete facility_favorite_path(facility)
    expect(response).to redirect_to(facility_path(facility))
    expect(user.reload.favorite_facilities).to be_empty
  end

  it "二重に追加しても 1 件のまま" do
    sign_in_as(user)
    2.times { post facility_favorite_path(facility) }
    expect(user.favorites.count).to eq(1)
  end

  it "ほかの人のお気に入りは見えない" do
    other = create(:user)
    create(:favorite, user: other, facility:)

    sign_in_as(user)
    get favorites_path

    expect(response.body).not_to include("ひまわりクラブ")
    expect(response.body).to include("まだお気に入りはありません")
  end
end
