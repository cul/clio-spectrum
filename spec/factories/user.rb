FactoryBot.define do
  factory :user do
    uid { 'example' }
    email { |u| "#{u.uid}@example.com" }
    password { 'secret' }
    # password_confirmation { |u| u.password }
  end
end
