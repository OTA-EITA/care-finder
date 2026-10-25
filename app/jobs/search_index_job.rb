# Elasticsearch バックエンドのとき、事業所の変更を索引に反映する。
# 保存のトランザクションが確定してから積むので（after_commit）、ロールバックされた変更は索引されない。
class SearchIndexJob < ApplicationJob
  queue_as :search

  retry_on Search::BackendUnavailable, wait: :polynomially_longer, attempts: 10

  def perform(facility_id)
    facility = Facility.includes(:features).find_by(id: facility_id)
    facility ? Search.backend.index(facility) : Search.backend.remove(facility_id)
  end
end
