NewBooks::Application.routes.draw do


  get "spectrum/search"

  get "admin/ingest_log"

  get "library_web/index"

  get "test_notification_error", :to => "application#test_notification_error"

  Blacklight.add_routes(self)
  
  root :to => "spectrum#search", :defaults => {:layout => 'quicksearch'}

  DeviseWind.add_routes(self)
 
  match 'admin/ingest_log', :to => "admin#ingest_log", :as => :admin_ingest_log


  match 'quicksearch/', :to => 'spectrum#search', :as => :quicksearch_index, :defaults => {:layout => 'quicksearch'}

  match "patron", :to => "patron#index", :as => :patron_index

  devise_for :users




  match 'databases', :to => 'catalog#index', :as => :databases_index
  match 'databases/:id(.:format)', :via => [:get], :to => 'catalog#show', :as => :databases_show
  match 'databases/facet/:id(.format)', :to => 'catalog#facet', :as => :databases_facet
  match 'databases/:id(.:format)', :via => [:put], :to => 'catalog#update', :as => :databases_update

  match 'journals', :to => 'catalog#index', :as => :journals_index
  match 'journals/:id(.:format)', :via => [:get], :to => 'catalog#show', :as => :journals_show
  match 'journals/facet/:id(.format)', :to => 'catalog#facet', :as => :journals_facet
  match 'journals/:id(.:format)', :via => [:put], :to => 'catalog#update', :as => :journals_update

  match 'library_web', :to => 'library_web#index', :as => :library_web_index

  match 'catalog', :to => 'catalog#index', :as => :base_catalog_index

  match 'advanced/:source(.:format)', :to => 'advanced#search', :as => :advanced_search

  match 'academic_commons', :to => 'catalog#index', :as => :academic_commons_index
  match 'academic_commons/range_limit(.:format)', :to => 'catalog#range_limit', :as => :academic_range_limit


  match 'archives', :to => 'catalog#index', :as =>  :archives_index
  match 'archives/:id(.:format)', :to => 'catalog#show', :as => :archives_show
  match 'archives/facet/:id(.format)', :to => 'catalog#facet', :as => :archives_facet

  match 'new_arrivals', :to => 'catalog#index', :as => :new_arrivals_index
  match 'new_arrivals/:id(.:format)', :to => 'catalog#show', :as => :new_arrivals_show
  match 'new_arrivals/facet/:id(.format)', :to => 'catalog#facet', :as => :new_arrivals_facet
  
  match 'backend/holdings/:id' => 'backend#holdings', :as => 'backend_holdings'
  match 'backend/holdings_mail/:id' => 'backend#holdings_mail', :as => 'backend_holdings_mail'
  match 'backend/clio_recall/:id', :to => "backend#clio_recall" , :as => :clio_recall
  match 'backend/feedback_mail', :to => "backend#feedback_mail"


  match 'lweb', :to => 'search#index', :as => :lweb_search, :defaults => {:categories => ['lweb']}

  match 'articles', :to => "articles#index", :as => :articles_index
  match 'articles/show', :to => "articles#show", :as => :articles_show
  match 'articles/search', :to => "articles#search", :as => :articles_search

  match 'ebooks', :to => 'spectrum#search', :as => :ebooks_index, :defaults => {:layout => 'ebooks'}

  match 'dissertations', :to => 'spectrum#search', :as => :dissertations_index, :defaults => {:layout => 'dissertations'}
  match 'newspapers', :to => 'spectrum#search', :as => :newspapers_index, :defaults => {:layout => 'newspapers'}

  match 'locations/show/:id', :id => /[^\/]+/, :to => "locations#show", :as => :location_display

  match 'welcome/versions', :to => "welcome#versions"

  scope "/admin" do
    match 'database_alerts/retrieve', :to => 'database_alerts#retrieve', :as => :database_alerts_retrieve
    resources :database_alerts, :except => ['edit']
  end
  namespace :admin do
    resources :locations
  end
end

