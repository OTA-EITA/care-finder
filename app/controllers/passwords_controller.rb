class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[edit update]
  rate_limit to: 10, within: 3.minutes, only: :create,
             with: -> { redirect_to new_password_path, alert: "操作が続いたため止めています。しばらく時間をおいてお試しください。" }

  def new
  end

  # 登録の有無が分からないよう、見つからなくても同じ応答を返す
  def create
    if user = User.find_by(email_address: params[:email_address])
      PasswordsMailer.reset(user).deliver_later
    end

    redirect_to new_session_path, notice: "登録されているメールアドレスであれば、再設定の案内を送りました。"
  end

  def edit
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      @user.sessions.destroy_all
      redirect_to new_session_path, notice: "パスワードを再設定しました。新しいパスワードでログインしてください。"
    else
      redirect_to edit_password_path(params[:token]), alert: "パスワードが一致しないか、12文字未満です。"
    end
  end

  private

  def set_user_by_token
    @user = User.find_by_password_reset_token!(params[:token])
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to new_password_path, alert: "再設定のリンクが無効か、期限が切れています。"
  end
end
