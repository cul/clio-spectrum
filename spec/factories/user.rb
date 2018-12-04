FactoryBot.define do
  factory :user do
    login { 'example' }
    email { |u| "#{u.login}@example.com" }
    password { 'secret' }
    password_confirmation(&:password)
  end
end
