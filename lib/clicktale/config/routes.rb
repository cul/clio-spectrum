

Rails.application.routes.draw do
  match 'clicktale/:filename.:format', :to => 'clicktale#show'
end


