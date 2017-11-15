FactoryBot.define do

  factory :item_alert do
    item_key '123'
    alert_type 'alert'
    message 'twas brillig'
    author_id 1
    source 'catalog'
  end

end
