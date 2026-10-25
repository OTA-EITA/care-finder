class FavoritesController < ApplicationController
  before_action :set_facility, only: %i[create destroy]

  def index
    @facilities = current_user.favorite_facilities.includes(:features).order("favorites.created_at DESC")
  end

  def create
    current_user.favorites.find_or_create_by!(facility: @facility)
    respond_with_button(notice: "お気に入りに追加しました")
  rescue ActiveRecord::RecordNotUnique
    respond_with_button(notice: "お気に入りに追加しました")
  end

  def destroy
    current_user.favorites.where(facility: @facility).destroy_all
    respond_with_button(notice: "お気に入りから外しました")
  end

  private

  def set_facility
    @facility = Facility.find(params[:facility_id])
  end

  def respond_with_button(notice:)
    respond_to do |format|
      format.turbo_stream { render :update }
      format.html { redirect_to facility_path(@facility), notice: }
    end
  end

  # POST のままログイン後に戻すと 404 になるので、戻り先は事業所のページにする
  def request_authentication
    session[:return_to_after_authenticating] = params[:facility_id] ? facility_url(params[:facility_id]) : request.url
    redirect_to new_session_path, alert: "お気に入りを使うにはログインしてください"
  end
end
