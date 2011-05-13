
NewBooks::Application.routes.draw do
  
  
  devise_for :users

  match 'backend/clio_recall/:id', :to => "backend#clio_recall" , :as => :clio_recall
  match 'locations/show/:id', :to => "locations#show", :as => :location_display

  namespace :admin do
    resources :locations
  end
end

