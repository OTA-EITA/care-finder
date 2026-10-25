require "rails_helper"

RSpec.describe "ログイン", type: :request do
  let(:user) { create(:user) }

  it "正しいパスワードでログインし、ログアウトできる" do
    sign_in_as(user)
    expect(response).to redirect_to(root_url)

    delete session_path
    expect(response).to redirect_to(new_session_path)
    expect(user.sessions.count).to eq(0)
  end

  it "誤ったパスワードでは日本語で知らせる" do
    sign_in_as(user, password: "wrong-password-123")
    follow_redirect!
    expect(response.body).to include("メールアドレスかパスワードが違います")
  end

  it "ログイン画面を表示する" do
    get new_session_path
    expect(response.body).to include("ログイン")
  end

  it "3分間に10回を超えると止める（総当たり対策）" do
    11.times { sign_in_as(user, password: "wrong-password-123") }
    follow_redirect!
    expect(response.body).to include("しばらく時間をおいて")
  end
end
