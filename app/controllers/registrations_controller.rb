class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 5, within: 1.hour, only: :create,
             with: -> { redirect_to new_registration_path, alert: "登録の操作が続いたため止めています。しばらく時間をおいてお試しください。" }

  def new
    @user = User.new
  end

  def create
    @user = User.new(params.expect(user: %i[email_address password password_confirmation]))
    if @user.save
      start_new_session_for @user
      redirect_to root_path, notice: "登録しました。気になる事業所をお気に入りに追加できます。"
    else
      render :new, status: :unprocessable_content
    end
  end
end
