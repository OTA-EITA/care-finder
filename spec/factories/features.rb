FactoryBot.define do
  factory :feature do
    sequence(:code) { |n| "feature_#{n}" }
    sequence(:name) { |n| "支援内容#{n}" }
    sequence(:position)
  end
end
