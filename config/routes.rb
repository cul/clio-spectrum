NewBooks::Application.routes.draw do
  Blacklight.add_routes(self)
  
  root :to => "search#index"
 
  match 'search/', :to => "search#index", :as => :search_index

  devise_for :users

  match 'databases', :to => 'catalog#index', :as => :databases_index
  match 'databases/:id(.:format)', :to => 'catalog#show', :as => :databases_show


  match 'catalog', :to => 'catalog#index', :as => :base_catalog_index

  match 'academic_commons', :to => 'catalog#index', :as => :academic_commons_index

  match 'new_arrivals', :to => 'catalog#index', :as => :new_arrivals_index
  match 'new_arrivals/:id(.:format)', :to => 'catalog#show', :as => :new_arrivals_show
  
  match 'backend/holdings/:id' => 'backend#holdings', :as => 'backend_holdings'
  match 'backend/holdings_mail/:id' => 'backend#holdings_mail', :as => 'backend_holdings_mail'
  match 'backend/clio_recall/:id', :to => "backend#clio_recall" , :as => :clio_recall
  match 'backend/feedback_mail', :to => "backend#feedback_mail"

  match 'lweb', :to => 'search#index', :as => :lweb_search, :defaults => {:categories => ['lweb']}

  match 'articles', :to => "articles#index", :as => :article_index
  match 'articles/show', :to => "articles#show", :as => :article_show
  match 'articles/search', :to => "articles#search", :as => :article_search

  match 'ebooks', :to => 'search#ebooks', :as => :search_ebooks

  match 'locations/show/:id', :id => /[^\/]+/, :to => "locations#show", :as => :location_display

  match 'welcome/versions', :to => "welcome#versions"

  namespace :admin do
    resources :locations
  end
end

