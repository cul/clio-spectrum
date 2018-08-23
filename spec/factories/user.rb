FactoryBot.define do

  factory :user do
    login { 'example' }
    email { |u| "#{u.login}@example.com" }
    password { 'secret' }
    password_confirmation { |u| u.password }
  end

end
