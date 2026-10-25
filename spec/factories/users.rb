FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password { "correct-horse-battery" }

    trait :staff do
      transient do
        facility { association(:facility) }
      end

      after(:create) do |user, ctx|
        create(:facility_membership, user:, facility: ctx.facility)
      end
    end
  end
end
