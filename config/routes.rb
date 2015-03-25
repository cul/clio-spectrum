Clio::Application.routes.draw do

  # This is getting masked.... try it up here?
  get "catalog/endnote", :as => "endnote_catalog"

  # resources :saved_list_items
  resources :saved_lists

  match 'lists/add/:item_key_list', via: [:get], to: 'saved_lists#add', as: :savedlist_add
  # Cannot restrict to POST, WIND auth always redirects via GET
  # match 'lists/add', via: [:post], to: 'saved_lists#add', as: :savedlist_add
  match 'lists/add', to: 'saved_lists#add', as: :savedlist_add
  match 'lists/remove', via: [:get], to: 'saved_lists#remove', as: :savedlist_remove
  match 'lists/move', via: [:get], to: 'saved_lists#move', as: :savedlist_move
  match 'lists/copy', via: [:get], to: 'saved_lists#copy', as: :savedlist_copy
  match '/lists/email(.:format)', to: 'saved_lists#email', as: :email_savedlist

  # These have to come LAST of the lists paths
  # They match any 2nd token as :owner, you'll never fallback to later routes
  match 'lists(/:owner(/:slug))', to: 'saved_lists#show', as: :lists
  match 'lists(/:owner(/:slug))/edit', to: 'saved_lists#edit', as: :edit_lists

  #  Use this section for ad-hoc routing overrides during localhost development
  if Rails.env.development?
    # such as... turn off unapi support, to simplify debugging?
    # match '/catalog/unapi' => proc { [404, {}, ['']] }
  end

  match 'catalog/advanced', to: 'catalog#index', as: :catalog_advanced, defaults: { q: '', show_advanced: 'true' }
  resources :item_alerts

  match 'item_alerts/:id/show_table_row(.:format)', to: 'item_alerts#show_table_row', as: :item_alert_show_table_row
  get 'spectrum/search'

  Blacklight.add_routes(self)

  root to: 'spectrum#search', defaults: { layout: 'quicksearch' }

  devise_for :users, controllers: { sessions: 'sessions' }

  match 'catalog', to: 'catalog#index', as: :base_catalog_index

  match 'quicksearch/', to: 'spectrum#search', as: :quicksearch_index, defaults: { layout: 'quicksearch' }

  # "Browser Options" are things like facet open/close state, view-style, etc.
  match 'set_browser_option', to: 'application#set_browser_option_handler'
  match 'get_browser_option', to: 'application#get_browser_option_handler'

  # Support for persisent selected-item lists
  match 'selected_items', to: 'application#selected_items_handler'

  devise_for :users

  match 'databases', to: 'catalog#index', as: :databases_index
  match 'databases/:id(.:format)', via: [:get], to: 'catalog#show', as: :databases_show
  match 'databases/facet/:id(.format)', to: 'catalog#facet', as: :databases_facet
  # match 'databases/:id(.:format)', via: [:put], to: 'catalog#update', as: :databases_update
  match 'databases/:id/track(.:format)', via: [:post], to: 'catalog#track', as: :databases_track

  match 'journals', to: 'catalog#index', as: :journals_index
  match 'journals/:id(.:format)', via: [:get], to: 'catalog#show', as: :journals_show
  match 'journals/facet/:id(.format)', to: 'catalog#facet', as: :journals_facet
  # match 'journals/:id(.:format)', via: [:put], to: 'catalog#update', as: :journals_update
  match 'journals/:id/track(.:format)', via: [:post], to: 'catalog#track', as: :journals_track

  match 'library_web', to: 'spectrum#search', as: :library_web_index, defaults: { layout: 'library_web' }

  match 'academic_commons', to: 'catalog#index', as: :academic_commons_index
  match 'academic_commons/range_limit(.:format)', to: 'catalog#range_limit', as: :academic_range_limit
  match 'academic_commons/facet/:id(.format)', to: 'catalog#facet', as: :academic_commons_facet

  match 'dcv', to: 'catalog#index', as: :dcv_index
  match 'dcv/facet/:id(.format)', to: 'catalog#facet', as: :dcv_facet

  match 'archives', to: 'catalog#index', as: :archives_index
  match 'archives/:id(.:format)', via: [:get], to: 'catalog#show', as: :archives_show
  match 'archives/facet/:id(.format)', to: 'catalog#facet', as: :archives_facet
  # match 'archives/:id(.:format)', via: [:put], to: 'catalog#update', as: :archives_update
  match 'archives/:id/track(.:format)', to: 'catalog#track', as: :archives_track

  # NEXT-483 A user should be able to browse results using previous/next
  # this requires GET ==> show, and POST ==> update, for reasons
  # explained in the ticket.
  match 'new_arrivals', to: 'catalog#index', as: :new_arrivals_index
  match 'new_arrivals/:id(.:format)', via: [:get], to: 'catalog#show', as: :new_arrivals_show
  match 'new_arrivals/facet/:id(.format)', to: 'catalog#facet', as: :new_arrivals_facet
  # match 'new_arrivals/:id(.:format)', via: [:put], to: 'catalog#update', as: :new_arrivals_update
  match 'new_arrivals/:id/track(.:format)', via: [:post], to: 'catalog#track', as: :new_arrivals_track

  match 'backend/holdings/:id' => 'backend#holdings', :as => 'backend_holdings'
  # unused
  # match 'backend/holdings_mail/:id' => 'backend#holdings_mail', :as => 'backend_holdings_mail'
  # match 'backend/clio_recall/:id', :to => "backend#clio_recall" , :as => :clio_recall
  # match 'backend/feedback_mail', :to => "backend#feedback_mail"

  match 'spectrum/fetch/:layout/:datasource', to: 'spectrum#fetch', as: 'spectrum_fetch'

  match 'articles', to: 'spectrum#search', as: :articles_index, defaults: { layout: 'articles' }
  # there's no 'articles' controller, and no item-detail page for articles
  # match 'articles/show', :to => "articles#show", :as => :articles_show

  match 'ebooks', to: 'spectrum#search', as: :ebooks_index, defaults: { layout: 'ebooks' }
  match 'dissertations', to: 'spectrum#search', as: :dissertations_index, defaults: { layout: 'dissertations' }
  # redirect newspapers to articles
  # match 'newspapers', to: 'spectrum#search', as: :newspapers_index, defaults: { layout: 'newspapers' }
  match '/newspapers', to: redirect('/articles')

  match 'locations/show/:id', id: /.*/, to: 'locations#show', as: :location_display

  # this catches certain broken sessions, when somehow controller == spectrum and action == show
  match 'spectrum/show', to: 'spectrum#search', defaults: { layout: 'quicksearch' }

  # we get this from blacklight - but we need it to accept POST as well...
  # email_catalog GET    /catalog/email(.:format)                       catalog#email
  # sms_catalog GET    /catalog/sms(.:format)                         catalog#sms
  match '/catalog/email(.:format)', to: 'catalog#email', as: :email_catalog
  match '/catalog/sms(.:format)', to: 'catalog#sms', as: :sms_catalog

  match '/catalog/email(.:format)', to: 'catalog#email', as: :email

  # Again, blacklight inserts this as GET, we need to support PUT
  # (due to Blacklight's mechanism of preserving search context.)
  # match 'catalog/:id/librarian_view', via: [:put], to: 'catalog#librarian_view_update'
  match 'catalog/:id/librarian_view_track', via: [:post], to: 'catalog#librarian_view_track'

  # no, this was never implemented
  # namespace :admin do
  #   resources :locations
  # end

  # No longer a given, must be part of Application's routes.rb, but only
  # inserted by the Blacklight MARC generator code.

  # Catalog stuff.
  get 'catalog/:id/librarian_view', :to => "catalog#librarian_view", :as => "librarian_view_catalog"

  # Call-Number Browse, based on Stanford Searchworks
  resources :browse, only: :index
  # Use distinct URLs for xhr v.s. html, to avoid cached-page problems, to customize html
  get 'browse/shelfkey_mini/:shelfkey(/:bib)', to: 'browse#shelfkey_mini', as: :browse_shelfkey_mini, :constraints => { :shelfkey => /[^\/]*/, :bib => /[^\/]*/ }
  get 'browse/shelfkey_full/:shelfkey(/:bib)', to: 'browse#shelfkey_full', as: :browse_shelfkey_full, :constraints => { :shelfkey => /[^\/]*/, :bib => /[^\/]*/ }


end


