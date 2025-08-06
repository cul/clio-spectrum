// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.

// Follow installation instructions:  https://github.com/rails/jquery-rails
//= require jquery
//= require jquery_ujs
//= require jquery-ui/widgets/sortable
// Draggable, so we can move modal windows around
//= require jquery-ui/widgets/draggable
// Datatables, for pretty log screens
//= require dataTables/jquery.dataTables

// from project Blacklight
//= require blacklight/blacklight

// For blacklight_range_limit built-in JS, if you don't want it you don't need
// this:
// # require 'blacklight_range_limit'

// These are all in support of the range-limit slider widget,
// which we don't have active at this time.
// # require flot/excanvas.min
// # require flot/jquery.flot
// # require flot/jquery.flot.selection
// # require blacklight_range_limit/range_limit_distro_facets
// # require blacklight_range_limit/range_limit_slider


// JavaScript plugins from Bootstrap

// The way to bring in Bootstrap 3 JavaScript, 
// suggested by Blacklight 5 code:
//= require bootstrap/transition
//= require bootstrap/collapse
//= require bootstrap/dropdown
//= require bootstrap/alert
//= require bootstrap/modal
//= require bootstrap/tooltip
//= require bootstrap/popover
//= require bootstrap/button

// Add 'tab', for navigation tab panels (My Borrowing Account)
//= require bootstrap/tab

// And, one specific Bootstrap-based add-on, installed locally
//= require bootstrap-datepicker

// Typeahead, for Best Bets, etc.
//= require twitter/typeahead.min

//= require advanced
//= require arrows
//= require articles
//= require astroids
//= require async-search
//= require best_bets
//= require catalog
//= require confetti
//= require datasources
//= require datatables
//= require dropdown_select
//= require google_analytics
// UNUSED //= require hathi
//= require holdings
//= require ie_warnings
//= require in_viewport
//= require item_actions
//= require item_alerts
//= require konami
//= require ldpd_feedback
//= require matomo
//= require my_account
//= require nearby
//= require resolver
//= require saved_lists
//= require scroll_memory
//= require preferences
//= require xls

// capybara-webkit doesn't support ES6 syntax
// To use code (like this) in this file, rename from .js to .js.erb
// moved to common_head  require_asset 'es6_bits' unless Rails.env.test? or browser.ie? 




