FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "role_#{n}" }
    description { Faker::Lorem.sentence }
    system_role { false }

    trait :system_role do
      system_role { true }
    end

    trait :custom_role do
      system_role { false }
    end

    trait :admin do
      name { 'admin' }
      description { 'System administrator with full access' }
      system_role { true }
    end

    trait :moderator do
      name { 'moderator' }
      description { 'Content moderator with limited admin access' }
      system_role { true }
    end

    trait :user do
      name { 'user' }
      description { 'Standard user with basic access' }
      system_role { true }
    end
  end
end
