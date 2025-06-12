FactoryBot.define do
  factory :permission do
    sequence(:name) { |n| "permission_#{n}" }
    description { Faker::Lorem.sentence }
    sequence(:resource) { |n| "resource_#{n}" }
    sequence(:action) { |_n| %w[read create update delete].sample }

    trait :read_permission do
      action { 'read' }
    end

    trait :write_permission do
      action { 'create' }
    end

    trait :update_permission do
      action { 'update' }
    end

    trait :delete_permission do
      action { 'delete' }
    end

    # Specific permission types
    trait :user_read do
      name { 'users.read' }
      resource { 'users' }
      action { 'read' }
      description { 'View users' }
    end

    trait :dashboard_access do
      name { 'dashboard.read' }
      resource { 'dashboard' }
      action { 'read' }
      description { 'Access dashboard' }
    end
  end
end
