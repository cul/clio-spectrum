// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.

// 3/2014, Switch to CDN:  https://github.com/kenn/jquery-rails-cdn
// - Remove "require jquery" from application.js

// jQuery - stay with 1.x series for now, for older IE support
//# require jquery-1.10.2.min.js
//# require jquery-1.11.0.min.js

// Unobtrusive scripting support for jQuery.  NOT part of JQuery CDN
//= require jquery_ujs

// from project Blacklight
//= require blacklight/blacklight

// These are all in support of the range-limit slider widget,
// which we don't have active at this time.
// # require flot/excanvas.min
// # require flot/jquery.flot
// # require flot/jquery.flot.selection
// # require blacklight_range_limit/range_limit_distro_facets
// # require blacklight_range_limit/range_limit_slider


// JavaScript plugins from Bootstrap

// Blacklight suggests including the following:
//= require bootstrap/transition
//= require bootstrap/collapse
//= require bootstrap/dropdown
//= require bootstrap/alert
//= require bootstrap/modal

// OLD way - bootstrap 2
// #  require bootstrap-datepicker
// #  require bootstrap-dropdown
// Popover extends ToolTip, so leave this in.  Order matters.
// #  require bootstrap-tooltip
// popovers used for source descriptions in aggregate searches, etc.
// #  require bootstrap-popover
// Not used?
// # require bootstrap-tab



//= require advanced
//= require articles
//= require async-search
//= require catalog
//= require datasources
//= require dropdown_select
//= require google_analytics
//= require hathi
//= require holdings
//= require ie_warnings
//= require item_actions
//= require item_alerts
//= require ldpd_feedback
//= require saved_lists


// was used in support of JavaScript landing-page switching,
// to carry-over "q" between forms.  No longer used.
// # require jquery.observe_field

// something about centering modal popups... selector doesn't seem to
// be hitting on anything anymore?
// # require modall_manager_override




