module FacilitiesHelper
  def service_type_options
    Facility::SERVICE_TYPE_LABELS.map { |value, label| { value:, label: } }
  end

  def distance_label(meters) = Recommendations::SimilarFacilities.distance_label(meters)

  def pickup_label(facility)
    case facility.pickup_available
    when true then "送迎あり"
    when false then "送迎なし"
    else "未登録"
    end
  end

  def data_source_note(facility)
    if facility.sample?
      "このページはサンプルデータ（架空）です。実在の事業所ではありません。"
    else
      as_of = facility.data_as_of ? l(facility.data_as_of, format: :long) : "取得日"
      "障害福祉サービス等情報公表システムのオープンデータ（#{as_of}時点）をもとに作成しています。最新の情報は事業所にご確認ください。"
    end
  end

  def openstreetmap_url(facility)
    point = facility.point or return nil
    lat = point.latitude.round(6)
    lng = point.longitude.round(6)
    "https://www.openstreetmap.org/?mlat=#{lat}&mlon=#{lng}#map=17/#{lat}/#{lng}"
  end

  # React の絞り込みパネルに渡す props（JS がなくても同じ内容をサーバー側のフォームで出す）
  def search_filter_props(criteria, result, features)
    {
      action: facilities_path,
      initial: criteria.as_json,
      facets: result.facets,
      serviceTypes: service_type_options,
      features: features.map { |f| { value: f.code, label: f.name } },
      stations: Geocoding::StationDirectory.new.names
    }
  end
end
