class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  # 総当たり対策。回数は Rails.cache（本番は ElastiCache Redis）に数えるので、タスクが複数あっても共有される
  rate_limit to: 10, within: 3.minutes, only: :create,
             with: -> { redirect_to new_session_path, alert: "ログインの試行が続いたため止めています。しばらく時間をおいてお試しください。" }

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "メールアドレスかパスワードが違います。"
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other, notice: "ログアウトしました。"
  end
end
