# 支援内容のタグと、動作確認用のサンプルデータ（架空）を入れる。何度実行しても同じ結果になる。
# 実在の事業所データは bin/rails open_data:import で WAM NET のオープンデータから取り込む。

feature_rows = [
  [ "exercise", "運動療育" ],
  [ "study", "学習支援" ],
  [ "sst", "ソーシャルスキルトレーニング" ],
  [ "individual", "個別療育" ],
  [ "music", "音楽療育" ],
  [ "outing", "外出・社会体験" ],
  [ "medical_care", "医療的ケアに対応" ],
  [ "severe", "重症心身障害児に対応" ]
]

feature_rows.each_with_index do |(code, name), index|
  Feature.find_or_initialize_by(code:).update!(name:, position: index)
end
features = Feature.all.index_by(&:code)

# 座標は駅から少し離した架空の地点。名前・住所・紹介文はすべて架空。
samples = [
  { no: "S0001", name: "サンプル ひまわり教室（架空）", kana: "さんぷる ひまわりきょうしつ", type: :houkago_day,
    pref: "北海道", city: "帯広市", addr: "西1条南1丁目（架空）", lat: 42.9201, lng: 143.2001, sat: "10:00-16:00", hol: "10:00-16:00",
    pickup: true, features: %w[exercise sst], description: "（サンプルの紹介文です）体を動かす活動と、集団での関わり方の練習を中心にしています。" },
  { no: "S0002", name: "サンプル ひまわり教室 第二（架空）", kana: "さんぷる ひまわりきょうしつ だいに", type: :houkago_day,
    pref: "北海道", city: "帯広市", addr: "東3条南5丁目（架空）", lat: 42.9248, lng: 143.2133, sat: "10:00-16:00",
    pickup: true, features: %w[exercise study], description: "（サンプルの紹介文です）宿題の時間と、運動の時間を分けて過ごします。" },
  { no: "S0003", name: "サンプル こども発達ルーム（架空）", kana: "さんぷる こどもはったつるーむ", type: :jidou_hattatsu,
    pref: "北海道", city: "帯広市", addr: "西10条南10丁目（架空）", lat: 42.9105, lng: 143.1880,
    pickup: false, features: %w[individual music], description: "（サンプルの紹介文です）未就学のお子さん向けに、個別の時間を中心にしています。" },
  { no: "S0004", name: "サンプル さくらスクール（架空）", kana: "さんぷる さくらすくーる", type: :houkago_day,
    pref: "北海道", city: "札幌市中央区", addr: "北2条西3丁目（架空）", lat: 43.0640, lng: 141.3480, sat: "09:00-17:00", sun: "09:00-17:00",
    pickup: nil, features: %w[study outing], description: nil },
  { no: "S0005", name: "サンプル てんのうじ放課後クラブ（架空）", kana: "さんぷる てんのうじほうかごくらぶ", type: :houkago_day,
    pref: "大阪府", city: "大阪市天王寺区", addr: "上本町（架空）", lat: 34.6520, lng: 135.5180, sat: "10:00-17:00", hol: "10:00-17:00",
    pickup: true, features: %w[exercise sst outing], description: "（サンプルの紹介文です）公園での外遊びや、買い物の練習をしています。" },
  { no: "S0006", name: "サンプル うえほんまちキッズ（架空）", kana: "さんぷる うえほんまちきっず", type: :jidou_hattatsu,
    pref: "大阪府", city: "大阪市天王寺区", addr: "上本町（架空）", lat: 34.6580, lng: 135.5200,
    pickup: true, features: %w[individual medical_care], description: "（サンプルの紹介文です）看護職員がいる時間帯は医療的ケアに対応しています。" },
  { no: "S0007", name: "サンプル なにわ学習ラボ（架空）", kana: "さんぷる なにわがくしゅうらぼ", type: :houkago_day,
    pref: "大阪府", city: "大阪市浪速区", addr: "難波中（架空）", lat: 34.6610, lng: 135.4990, sat: "10:00-16:00",
    pickup: false, features: %w[study individual], description: nil },
  { no: "S0008", name: "サンプル あおぞらクラブ（架空）", kana: "さんぷる あおぞらくらぶ", type: :houkago_day,
    pref: "北海道", city: "帯広市", addr: "西2条南9丁目（架空）", lat: 42.9150, lng: 143.2010, sat: "09:30-16:30", hol: "09:30-16:30",
    pickup: true, features: %w[exercise outing], description: "（サンプルの紹介文です）長い休みには公園や図書館へ出かけます。" },
  { no: "S0009", name: "サンプル もりのこルーム（架空）", kana: "さんぷる もりのこるーむ", type: :jidou_hattatsu,
    pref: "北海道", city: "帯広市", addr: "東1条南4丁目（架空）", lat: 42.9215, lng: 143.2080, sat: "10:00-15:00",
    pickup: false, features: %w[individual music], description: "（サンプルの紹介文です）歌や手遊びを取り入れた個別の時間を用意しています。" },
  { no: "S0010", name: "サンプル とかち学習スタジオ（架空）", kana: "さんぷる とかちがくしゅうすたじお", type: :houkago_day,
    pref: "北海道", city: "帯広市", addr: "西5条南12丁目（架空）", lat: 42.9120, lng: 143.1975, sat: "10:00-16:00",
    pickup: true, features: %w[study sst], description: "（サンプルの紹介文です）宿題のあとに、話し合いやゲームで関わり方を練習します。" },
  { no: "S0011", name: "サンプル はれのひ教室（架空）", kana: "さんぷる はれのひきょうしつ", type: :houkago_day,
    pref: "北海道", city: "帯広市", addr: "東4条南8丁目（架空）", lat: 42.9190, lng: 143.2150, hol: "10:00-16:00",
    pickup: nil, features: %w[exercise music], description: nil },
  { no: "S0012", name: "サンプル こぐまキッズ（架空）", kana: "さんぷる こぐまきっず", type: :jidou_hattatsu,
    pref: "北海道", city: "帯広市", addr: "西8条南6丁目（架空）", lat: 42.9230, lng: 143.1930,
    pickup: true, features: %w[individual severe], description: "（サンプルの紹介文です）重症心身障害のあるお子さんも受け入れています。" },
  { no: "S0013", name: "サンプル ゆうひが丘スクール（架空）", kana: "さんぷる ゆうひがおかすくーる", type: :houkago_day,
    pref: "大阪府", city: "大阪市天王寺区", addr: "夕陽丘町（架空）", lat: 34.6550, lng: 135.5110, sat: "10:00-16:00",
    pickup: true, features: %w[study sst], description: "（サンプルの紹介文です）少人数のグループで学習と会話の練習をしています。" },
  { no: "S0014", name: "サンプル てらまちキッズラボ（架空）", kana: "さんぷる てらまちきっずらぼ", type: :houkago_day,
    pref: "大阪府", city: "大阪市天王寺区", addr: "生玉町（架空）", lat: 34.6600, lng: 135.5150, sat: "10:00-17:00", hol: "10:00-17:00",
    pickup: false, features: %w[exercise music], description: nil }
]

samples.each do |s|
  facility = Facility.find_or_initialize_by(source: "sample", source_record_no: s[:no])
  facility.update!(
    name: s[:name], name_kana: s[:kana], service_type: s[:type], corporation_name: "サンプル法人（架空）",
    prefecture: s[:pref], municipality: s[:city], address_line: s[:addr], latitude: s[:lat], longitude: s[:lng],
    capacity: 10, hours_weekday: "13:00-18:00", hours_saturday: s[:sat], hours_sunday: s[:sun], hours_holiday: s[:hol],
    closed_days: "年末年始", pickup_available: s[:pickup], description: s[:description],
    features: s[:features].map { features.fetch(_1) }
  )
end

# デモ用アカウント（開発・テスト環境だけ）。本番では作らない
if Rails.env.local?
  demo_password = "demo-password-2026"
  family = User.find_or_initialize_by(email_address: "family@example.com")
  family.update!(password: demo_password) if family.new_record?

  staff = User.find_or_initialize_by(email_address: "staff@example.com")
  staff.update!(password: demo_password) if staff.new_record?
  FacilityMembership.find_or_create_by!(user: staff, facility: Facility.find_by!(source: "sample", source_record_no: "S0001"))

  puts "デモ用アカウント: family@example.com / staff@example.com（パスワード: #{demo_password}）"
end
