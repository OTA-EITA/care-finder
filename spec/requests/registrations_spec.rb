require "rails_helper"

RSpec.describe "新規登録", type: :request do
  it "登録するとログインした状態になる" do
    expect {
      post registration_path, params: { user: { email_address: "family@example.com", password: "correct-horse-battery", password_confirmation: "correct-horse-battery" } }
    }.to change(User, :count).by(1)

    expect(response).to redirect_to(root_path)
    follow_redirect!
    expect(response.body).to include("ログアウト")
  end

  it "入力に誤りがあれば 422 で理由を表示する" do
    post registration_path, params: { user: { email_address: "bad", password: "short", password_confirmation: "short" } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("メールアドレスの形式が正しくありません", "パスワードは12文字以上で入力してください")
  end

  it "登録画面を表示する" do
    get new_registration_path
    expect(response).to have_http_status(:ok)
  end

  it "短時間に何度も登録しようとすると止める" do
    6.times do |i|
      post registration_path, params: { user: { email_address: "u#{i}@example.com", password: "correct-horse-battery", password_confirmation: "correct-horse-battery" } }
    end
    expect(response).to redirect_to(new_registration_path)
    expect(flash[:alert]).to include("しばらく時間をおいて")
  end
end
