NewBooks::Application.routes.draw do
  #Blacklight.add_routes(self)
  
  #root :to => "catalog#index"
  
  devise_for :users

  match 'backend/clio_recall/:id', :to => "backend#clio_recall" , :as => :clio_recall
  match 'locations/show/:id', :to => "locations#show", :as => :location_display
  match 'backend/feedback_mail', :to => "backend#feedback_mail"

  namespace :admin do
    resources :locations
  end
end

