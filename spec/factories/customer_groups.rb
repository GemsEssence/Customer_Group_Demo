FactoryBot.define do
  factory :customer_group do
    name { Faker::Commerce.department }
  end
end
