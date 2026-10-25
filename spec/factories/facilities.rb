FactoryBot.define do
  factory :facility do
    source { "sample" }
    sequence(:source_record_no) { |n| "S#{n.to_s.rjust(6, '0')}" }
    data_as_of { Date.new(2026, 3, 31) }
    service_type { :houkago_day }
    sequence(:name) { |n| "サンプル放課後クラブ#{n}" }
    prefecture { "北海道" }
    municipality { "帯広市" }
    address_line { "西1条南1丁目1" }
    latitude { 42.9176 }
    longitude { 143.2042 }
    capacity { 10 }
    hours_weekday { "13:00-18:00" }

    trait :jidou_hattatsu do
      service_type { :jidou_hattatsu }
    end

    trait :saturday do
      hours_saturday { "10:00-16:00" }
    end

    trait :holiday do
      hours_holiday { "10:00-16:00" }
    end

    trait :pickup do
      pickup_available { true }
    end

    trait :wamnet do
      source { "wamnet" }
    end

    trait :osaka do
      prefecture { "大阪府" }
      municipality { "大阪市天王寺区" }
      latitude { 34.6466 }
      longitude { 135.5141 }
    end
  end
end
