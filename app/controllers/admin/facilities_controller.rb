module Admin
  class FacilitiesController < BaseController
    before_action :set_facility, only: %i[edit update]

    def index
      @facilities = current_user.managed_facilities.includes(:features).order(:name_kana, :id)
    end

    def edit
      @features = Feature.ordered
    end

    # 支援内容の付け替えは保存前に中間テーブルへ書かれるので、入力エラーのときはまとめて取り消す
    def update
      saved = false
      Facility.transaction do
        saved = @facility.update(facility_params)
        raise ActiveRecord::Rollback unless saved
      end

      if saved
        redirect_to edit_admin_facility_path(@facility), notice: "掲載情報を更新しました。"
      else
        @facility.features.reset
        @features = Feature.ordered
        render :edit, status: :unprocessable_content
      end
    end

    private

    # 担当外の事業所は「存在しない」と同じ 404 にして、ID の有無も漏らさない
    def set_facility
      @facility = current_user.managed_facilities.find(params[:id])
    end

    # 編集できるのは職員が入力する項目だけ（Facility::STAFF_EDITABLE_ATTRIBUTES + 支援内容）
    def facility_params
      permitted = params.expect(facility: [ *Facility::STAFF_EDITABLE_ATTRIBUTES, { feature_ids: [] } ])
      if permitted.key?(:pickup_available)
        permitted[:pickup_available] = ActiveModel::Type::Boolean.new.cast(permitted[:pickup_available].presence)
      end
      if permitted.key?(:feature_ids)
        permitted[:feature_ids] = Feature.where(id: permitted[:feature_ids].compact_blank).pluck(:id)
      end
      permitted
    end
  end
end
