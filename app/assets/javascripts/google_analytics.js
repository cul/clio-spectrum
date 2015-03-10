$(document).ready(function() {

  // UNIVERSAL TRACKING CODE FROM GA WEBSITE

  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

  // Point our running instance to the appropriate GA property definition
  //
  if ($("body").data("rails-env") == 'development'){
    ga('create', google_analytics_web_property_id, 'none');
  }
  else{
    ga('create', google_analytics_web_property_id, 'columbia.edu');
  }

  // This sends the a normal page-view to Google Analytics.
  // It runs once on page load.
  ga('send', 'pageview');


  // The below attaches a Click-handler function to selected <A HREF> links,
  // which will send a GA custom event when that link is clicked.

  // Click-Tracking as GA Events, based on:
  //   http://www.lunametrics.com/blog/2013/07/02/jquery-event-tracking
  // Apply to all off-site <A> tags, based on:
  //   http://www.electrictoolbox.com/jquery-open-offsite-links-new-window/

  $(document).on('click', 'a', function(event) {

    if (this.hostname && this.hostname === location.hostname){
      if (!($(this).hasClass('dropdown-link'))){
        return;
      }
    }

    // Gather up values at time of click, not at first load, to allow
    // for ajax updates to, e.g., href labels or targets

    var href   = $(this).attr("href");
    var target = $(this).attr("target");
    var text   = $(this).text();

    // The GA Category/Action may be given at a higher DOM level,
    // e.g., at the root of an html menu/list of links, or a container div,

    var category = $(this).closest("[data-ga-category]").data("ga-category") || "Outbound Link";
    var action = $(this).closest("[data-ga-action]").data("ga-action") || "Click";
    var label = $(this).data("ga-label") || text;

    var open_new_window = false;

    // Offsite links will open a new window unless it is a download link

    //if (!($(this).hasClass('dropdown-link'))){
    if ((this.hostname && this.hostname !== location.hostname) && (!($(this).hasClass('download')))){
      open_new_window = true;
    }

    if (open_new_window){
      event.preventDefault(); // don't open the link yet
    }

    logToConsole("ga('send','event','"+category+"','"+action+"','"+label+"')");
    ga('send', 'event', category, action, label);

    if (open_new_window){
      setTimeout(function() { // now wait 300 milliseconds...
        window.open(href, (!target ? "_blank" : target)); // ...and open in new blank window
      },300);
    }
  });


  $(this).bind('copy', function() {
    var selectedText = "";
    if (window.getSelection) {
        selectedText = window.getSelection().toString();
    } else if (document.selection && document.selection.type != "Control") {
        selectedText = document.selection.createRange().text;
    }
    if (selectedText.length > 0) {
      // console.log('copy event')
      // What GA category/action/label do we want to log this event as?
    }
    return true;
  });
});


function logToConsole(message) {
  if ($("body").data("rails-env") == 'development') {
    console.log(message)
  }
}
