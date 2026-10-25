module Admin
  # 事業所の職員向け画面。どの事業所を触れるかは各コントローラーで current_user.managed_facilities に絞る
  class BaseController < ApplicationController
    before_action :require_staff

    private

    def require_staff
      render "admin/forbidden", status: :forbidden unless current_user.staff?
    end
  end
end
