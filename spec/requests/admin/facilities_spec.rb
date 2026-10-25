require "rails_helper"

RSpec.describe "管理画面: 事業所の掲載情報", type: :request do
  let(:own) { create(:facility, name: "自分の事業所") }
  let(:others) { create(:facility, name: "よその事業所", description: "元の紹介文") }
  let(:staff) { create(:user, :staff, facility: own) }
  let!(:exercise) { create(:feature, code: "exercise", name: "運動療育") }

  it "ログインしていなければログイン画面へ" do
    get admin_facilities_path
    expect(response).to redirect_to(new_session_path)
  end

  it "事業所に所属していないユーザーは 403" do
    sign_in_as(create(:user))
    get admin_facilities_path
    expect(response).to have_http_status(:forbidden)
  end

  it "担当の事業所だけを一覧に出す" do
    others
    sign_in_as(staff)
    get admin_facilities_path
    expect(response.body).to include("自分の事業所")
    expect(response.body).not_to include("よその事業所")
  end

  it "担当の事業所の紹介文・送迎・支援内容を更新できる" do
    sign_in_as(staff)
    get edit_admin_facility_path(own)
    expect(response).to have_http_status(:ok)

    patch admin_facility_path(own), params: { facility: { description: "体を動かす療育です", pickup_available: "true", feature_ids: [ exercise.id ] } }

    expect(response).to redirect_to(edit_admin_facility_path(own))
    expect(own.reload).to have_attributes(description: "体を動かす療育です", pickup_available: true, features: [ exercise ])
  end

  it "送迎を未登録に戻せる" do
    own.update!(pickup_available: true)
    sign_in_as(staff)
    patch admin_facility_path(own), params: { facility: { pickup_available: "" } }
    expect(own.reload.pickup_available).to be_nil
  end

  it "ほかの事業所は表示も更新もできない（404）" do
    sign_in_as(staff)

    get edit_admin_facility_path(others)
    expect(response).to have_http_status(:not_found)

    patch admin_facility_path(others), params: { facility: { description: "書き換え" } }
    expect(response).to have_http_status(:not_found)
    expect(others.reload.description).to eq("元の紹介文")
  end

  it "公開データの項目（名前など）は送られても変えない" do
    sign_in_as(staff)
    patch admin_facility_path(own), params: { facility: { name: "改ざん", description: "紹介文" } }
    expect(own.reload.name).to eq("自分の事業所")
  end

  it "入力に誤りがあれば 422 で、支援内容の変更も残さない" do
    sign_in_as(staff)
    patch admin_facility_path(own), params: { facility: { description: "あ" * 2001, feature_ids: [ exercise.id ] } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("紹介文は2000文字以内で入力してください")
    expect(own.reload.features).to be_empty
  end

  it "存在しない支援内容の id は無視する" do
    sign_in_as(staff)
    patch admin_facility_path(own), params: { facility: { feature_ids: [ exercise.id, 0 ] } }
    expect(own.reload.features).to eq([ exercise ])
  end
end
