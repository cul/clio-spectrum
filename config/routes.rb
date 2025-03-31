Rails.application.routes.draw do

  devise_for :users, controllers: { sessions: 'users/sessions', :omniauth_callbacks => "users/omniauth_callbacks" }

  devise_scope :user do
    get 'sign_in', :to => 'users/sessions#new', :as => :new_user_session
    get 'sign_out', :to => 'users/sessions#destroy', :as => :destroy_user_session
  end

  resources :preferences do
    collection do
      post 'bentos'
      get 'bentos'
    end
  end

  concern :range_searchable, BlacklightRangeLimit::Routes::RangeSearchable.new

  # Authenticated CUL Staff can download search results as XLS
  get 'catalog/xls_form'
  get 'catalog/xls_download'
  get 'catalog/xlsx_form'
  get 'catalog/xlsx_download'
  # multi-format download handler
  get 'catalog/download'

  ##### COPIED FROM VANILLA BLACKLIGHT 6.0 APP
  mount Blacklight::Engine => '/'

  Blacklight::Marc.add_routes(self)

  # clio:
  root to: 'spectrum#search', defaults: { layout: 'quicksearch' }
  # blacklight:
  # root to: "catalog#index"

  concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
    concerns :range_searchable
  end

  concern :exportable, Blacklight::Routes::Exportable.new
  # old clio:
  # devise_for :users, controllers: { sessions: 'sessions' }

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end
  #####

  # blacklight-marc gem gives endnote as an action, not just format of 'show',
  # to allow endnote export of multiple records at once
  get 'catalog/endnote', as: 'endnote_catalog'

  # special admin pages
  get 'admin/system'
  get 'admin/format_icons'
  get 'admin/request_services'

  # and this..
  get 'catalog/:id/librarian_view', to: 'catalog#librarian_view', as: 'librarian_view_catalog'
  # Again, blacklight inserts this as GET, we need to support PUT
  # (due to Blacklight's mechanism of preserving search context.)
  # match 'catalog/:id/librarian_view', via: [:put], to: 'catalog#librarian_view_update'
  match 'catalog/:id/librarian_view_track', via: [:post], to: 'catalog#librarian_view_track'

  # resources :saved_list_items
  resources :saved_lists

  match 'lists/add(/:item_key_list)', via: [:get, :post], to: 'saved_lists#add', as: :savedlist_add
  # Cannot restrict to POST, WIND auth always redirects via GET
  # get 'lists/add', via: [:post], to: 'saved_lists#add', as: :savedlist_add
  # get 'lists/add', to: 'saved_lists#add'

  get 'lists/remove', via: [:get], to: 'saved_lists#remove', as: :savedlist_remove
  get 'lists/move', via: [:get], to: 'saved_lists#move', as: :savedlist_move
  get 'lists/copy', via: [:get], to: 'saved_lists#copy', as: :savedlist_copy
  get '/lists/email(.:format)', to: 'saved_lists#email', as: :email_savedlist

  # These have to come LAST of the lists paths
  # They get any 2nd token as :owner, you'll never fallback to later routes
  get 'lists(/:owner(/:slug))', to: 'saved_lists#show', as: :lists
  get 'lists(/:owner(/:slug))/edit', to: 'saved_lists#edit', as: :edit_lists

  #  Use this section for ad-hoc routing overrides during localhost development
  if Rails.env.development?
    # such as... turn off unapi support, to simplify debugging?
    # get '/catalog/unapi' => proc { [404, {}, ['']] }
  end

  resources :item_alerts

  get 'item_alerts/:id/show_table_row(.:format)', to: 'item_alerts#show_table_row', as: :item_alert_show_table_row

  get 'spectrum/search'

  get 'catalog', to: 'catalog#index', as: :catalog_index

  get 'quicksearch/', to: 'spectrum#search', as: :quicksearch_index, defaults: { layout: 'quicksearch' }

  # "Browser Options" are things like facet open/close state, view-style, etc.
  get 'set_browser_option', to: 'application#set_browser_option_handler'
  get 'get_browser_option', to: 'application#get_browser_option_handler'

  # Support for persisent selected-item lists
  match 'selected_items', via: [:get, :post], to: 'application#selected_items_handler'

  get 'databases', to: 'catalog#index', as: :databases_index
  get 'databases/:id(.:format)', via: [:get], to: 'catalog#show', as: :databases_show
  get 'databases/facet/:id(.format)', to: 'catalog#facet', as: :databases_facet
  post 'databases/:id/track(.:format)', via: [:post], to: 'catalog#track', as: :databases_track
  get 'databases/:id/librarian_view', to: 'catalog#librarian_view', as: 'librarian_view_databases'
  match 'databases/:id/librarian_view_track', via: [:post], to: 'databases#librarian_view_track'

  get 'journals', to: 'catalog#index', as: :journals_index
  get 'journals/:id(.:format)', via: [:get], to: 'catalog#show', as: :journals_show
  get 'journals/facet/:id(.format)', to: 'catalog#facet', as: :journals_facet
  post 'journals/:id/track(.:format)', via: [:post], to: 'catalog#track', as: :journals_track
  get 'journals/:id/librarian_view', to: 'catalog#librarian_view', as: 'librarian_view_journals'
  match 'journals/:id/librarian_view_track', via: [:post], to: 'journals#librarian_view_track'

  # get 'library_web', to: 'spectrum#search', as: :library_web_index, defaults: { layout: 'library_web' }

  # Library Web via Custom Search API
  get 'lweb', to: 'spectrum#search', as: :lweb_index, defaults: { layout: 'lweb' }
  # redirect old url to new url
  get '/library_web', to: redirect('/lweb')

  # Academic Commons via API
  # new url
  get 'ac', to: 'spectrum#search', as: :ac_index, defaults: { layout: 'ac' }
  # support old url
  get 'academic_commons', to: 'spectrum#search', as: :academic_commons_index, defaults: { layout: 'ac' }

  # get 'academic_commons', to: 'catalog#index', as: :academic_commons_index
  # get 'academic_commons/range_limit(.:format)', to: 'catalog#range_limit', as: :academic_range_limit
  # get 'academic_commons/facet/:id(.format)', to: 'catalog#facet', as: :academic_commons_facet

  get 'geo', to: 'catalog#index', as: :geo_index
  get 'geo/facet/:id(.format)', to: 'catalog#facet', as: :geo_facet

  get 'dlc', to: 'catalog#index', as: :dlc_index
  get 'dlc/facet/:id(.format)', to: 'catalog#facet', as: :dlc_facet

  get 'archives', to: 'catalog#index', as: :archives_index
  get 'archives/:id(.:format)', via: [:get], to: 'catalog#show', as: :archives_show
  get 'archives/facet/:id(.format)', to: 'catalog#facet', as: :archives_facet
  post 'archives/:id/track(.:format)', to: 'catalog#track', as: :archives_track
  get 'archives/:id/librarian_view', to: 'catalog#librarian_view', as: 'librarian_view_archives'
  match 'archives/:id/librarian_view_track', via: [:post], to: 'archives#librarian_view_track'

  get 'govdocs', to: 'catalog#index', as: :govdocs_index
  get 'govdocs/:id(.:format)', via: [:get], to: 'catalog#show', as: :govdocs_show
  get 'govdocs/facet/:id(.format)', to: 'catalog#facet', as: :govdocs_facet
  post 'govdocs/:id/track(.:format)', to: 'catalog#track', as: :govdocs_track
  get 'govdocs/:id/librarian_view', to: 'catalog#librarian_view', as: 'librarian_view_govdocs'
  match 'govdocs/:id/librarian_view_track', via: [:post], to: 'govdocs#librarian_view_track'

  # NEXT-483 A user should be able to browse results using previous/next
  # this requires GET ==> show, and POST ==> update, for reasons
  # explained in the ticket.
  get 'new_arrivals', to: 'catalog#index', as: :new_arrivals_index
  get 'new_arrivals/:id(.:format)', via: [:get], to: 'catalog#show', as: :new_arrivals_show
  get 'new_arrivals/facet/:id(.format)', to: 'catalog#facet', as: :new_arrivals_facet
  post 'new_arrivals/:id/track(.:format)', via: [:post], to: 'catalog#track', as: :new_arrivals_track
  get 'new_arrivals/:id/librarian_view', to: 'catalog#librarian_view', as: 'librarian_view_new_arrivals'
  match 'new_arrivals/:id/librarian_view_track', via: [:post], to: 'new_arrivals#librarian_view_track'

  get 'backend/holdings/:id' => 'backend#holdings', :as => 'backend_holdings'
  get 'backend/offsite/:id' => 'backend#offsite', :as => 'backend_offsite', constraints: { id: /.+/ }

  get 'catalog/hathi_holdings/:id' => 'catalog#hathi_holdings', :as => 'hathi_holdings'

  get 'spectrum/hits/:datasource', to: 'spectrum#hits', as: 'spectrum_hits'

  get 'spectrum/searchjson/:layout/:datasource', to: 'spectrum#searchjson', as: 'spectrum_searchjson'

  match 'articles', to: 'spectrum#search', as: :articles_index, via: [:get, :post], defaults: { layout: 'articles' }

  match 'articles/facet', to: 'spectrum#facet', as: :articles_facet, via: [:get, :post], defaults: { layout: 'articles' }

  # there's no 'articles' controller, and no item-detail page for articles
  # get 'articles/show', :to => "articles#show", :as => :articles_show
  
  get 'ebooks', to: 'spectrum#search', as: :ebooks_index, defaults: { layout: 'ebooks' }
  get 'dissertations', to: 'spectrum#search', as: :dissertations_index, defaults: { layout: 'dissertations' }
  get 'research_data', to: 'spectrum#search', as: :data_index, defaults: { layout: 'research_data' }

  # redirect newspapers to articles
  get '/newspapers', to: redirect('/articles')

  get 'locations/show/:id', id: /[^\/]+/, to: 'locations#show', as: :location_display

  # this catches certain broken sessions, when somehow controller == spectrum and action == show
  get 'spectrum/show', to: 'spectrum#search', defaults: { layout: 'quicksearch' }

  # we get this from blacklight - but we need it to accept POST as well...
  # email_catalog GET    /catalog/email(.:format)                       catalog#email
  # sms_catalog GET    /catalog/sms(.:format)                         catalog#sms
  # 3/15, try without?
  # match '/catalog/email(.:format)' => 'catalog#email', as: :email_catalog, via: [:post]
  # match '/catalog/sms(.:format)' => 'catalog#sms', as: :sms_catalog, via: [:post]

  match '/catalog/email(.:format)', via: [:get, :post], to: 'catalog#email', as: :email

  # Again, blacklight inserts this as GET, we need to support PUT
  # (due to Blacklight's mechanism of preserving search context.)
  post 'catalog/:id/librarian_view_track', via: [:post], to: 'catalog#librarian_view_track'

  # Call-Number Browse, based on Stanford Searchworks
  resources :browse, only: :index
  # Use distinct URLs for xhr v.s. html, to avoid cached-page problems, to customize html
  get 'browse/shelfkey_mini/:shelfkey(/:bib)', to: 'browse#shelfkey_mini', as: :browse_shelfkey_mini, constraints: { shelfkey: /[^\/]*/, bib: /[^\/]*/ }
  get 'browse/shelfkey_full/:shelfkey(/:bib)', to: 'browse#shelfkey_full', as: :browse_shelfkey_full, constraints: { shelfkey: /[^\/]*/, bib: /[^\/]*/ }

  # Rails 4 - move this to bottom, so it doesn't override other
  # routes that also go to 'catalog#index'
  # (Didn't have to do this with Rails 3 - what changed???)
  get 'catalog/advanced', to: 'catalog#index', as: :catalog_advanced, defaults: { q: '', show_advanced: 'true' }

  # authorities
  resources :authorities, only: [:index, :show]

  # fetch by term, instead of id
  get 'authorities/author/:author', to: 'authorities#author', as: :author_authorities
  get 'authorities/subject/:subject', to: 'authorities#subject'

  # and the MARC "librarian view" for each
  get 'authorities/author_marc/:author', to: 'authorities#author_marc'
  get 'authorities/subject_marc/:subject', to: 'authorities#subject_marc'

  get 'checked_out_items(/:uni)', to: 'spectrum#checked_out_items', as: :checked_out_items

  # https://github.com/pelargir/auto-session-timeout
  get 'active', to: 'application#render_session_status'
  get 'timeout', to: 'application#render_session_timeout'

  # NEXT-1594 - BestBets CRUD functionality externalized
  # resources :best_bets do
  #   collection do
  #     get 'hits'
  #   end
  # end

  resources :logs do
    collection do
      # bounce the user to another URL, and log it
      get 'bounce'
      # List known log sets
      get 'sets'
    end
  end
end
