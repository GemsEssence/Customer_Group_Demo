FactoryBot.define do
  factory :customer do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    mobile_no { Faker::PhoneNumber.cell_phone_in_e164 }
    address { Faker::Address.full_address }
    is_active { true }
    association :customer_group
  end
end