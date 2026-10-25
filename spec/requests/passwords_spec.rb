require "rails_helper"

RSpec.describe "パスワード再設定", type: :request do
  let(:user) { create(:user) }

  it "メールを送り、トークンで新しいパスワードにできる" do
    get new_password_path
    expect(response).to have_http_status(:ok)

    expect { post passwords_path, params: { email_address: user.email_address } }
      .to have_enqueued_mail(PasswordsMailer, :reset)
    expect(response).to redirect_to(new_session_path)

    token = user.password_reset_token
    get edit_password_path(token)
    expect(response).to have_http_status(:ok)

    put password_path(token), params: { password: "new-correct-horse", password_confirmation: "new-correct-horse" }
    expect(response).to redirect_to(new_session_path)
    expect(user.reload.authenticate("new-correct-horse")).to be_truthy
  end

  it "確認用が一致しなければやり直し" do
    token = user.password_reset_token
    put password_path(token), params: { password: "new-correct-horse", password_confirmation: "different-horse" }
    expect(response).to redirect_to(edit_password_path(token))
  end

  it "無効なトークンは再発行へ" do
    get edit_password_path("invalid")
    expect(response).to redirect_to(new_password_path)
  end
end
