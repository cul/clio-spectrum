
// OLDER CODE, COPIED FROM _common_head.html.haml
// 
// var _gaq = _gaq || [];
// _gaq.push(['_setAccount', '#{GoogleAnalytics.web_property_id}']);
// _gaq.push(['_setSiteSpeedSampleRate', 100]);
// _gaq.push(['_trackPageview']);
// 
// (function() {
//   var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
//   ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
//   var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
// })();



$(document).ready(function() {

  // UNIVERSAL TRACKING CODE FROM GA WEBSITE

  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

  // Point our running instance to the appropriate GA property definition
  // ga('create', google_analytics_web_property_id, 'columbia.edu');
  // FOR LOCALHOST DEVELOPMENT USE THIS LINE INSTEAD
  ga('create', google_analytics_web_property_id, 'none');

  ga('send', 'pageview');




  // Click-Tracking as GA Events, based on:
  //   http://www.lunametrics.com/blog/2013/07/02/jquery-event-tracking
  // Apply to all off-site <A> tags, based on:
  //   http://www.electrictoolbox.com/jquery-open-offsite-links-new-window/

  // $("a.linkout").each(function() {	
  $('a[href]').filter( function() {return this.hostname && this.hostname !== location.hostname} ).each(function() {

    console.log("found a.href href=["+href+"] text=["+text+"]")

    $(this).click(function(event) { // when someone clicks these links
      // Gather up values at time of click, not at first load, to allow
      // for ajax updates to, e.g., href labels or targets

      var href   = $(this).attr("href");
      var target = $(this).attr("target");
      var text   = $(this).text();

      // The GA Category/Action may be given at a higher DOM level,
      // e.g., at the root of an html menu/list of links, or a container div,
      var category = $(this).closest("[data-ga-category]").data("ga-category") || "Outbound Link";
      var action = $(this).closest("[data-ga-action]").data("ga-action") || "Click";
      // Should the GA label default to the text or the URL?
      var label = $(this).data("ga-label") || text;

      var href_at_click = $(this).attr("href");
      console.log("click! href_at_click=["+href_at_click+"]")

      event.preventDefault(); // don't open the link yet

      // _gaq.push(["_trackEvent", category, action, label]); // create a custom event
      // _trackEvent(category, action, label)
      // console.log("ga('send','event','"+category+"','"+action+"','"+label+"')")
      ga('send', 'event', category, action, label);

      setTimeout(function() { // now wait 300 milliseconds...
        window.open(href, (!target ? "_blank" : target)); // ...and open in new blank window
      },300);
    });
  });


  $(this).bind('copy', function() {
    var selectedText = "";
    if (window.getSelection) {
        selectedText = window.getSelection().toString()
    } else if (document.selection && document.selection.type != "Control") {
        selectedText = document.selection.createRange().text
    }
    if (selectedText.length > 0) {
      // console.log('copy event')
      // What GA category/action/label do we want to log this event as?
    }
    return true;
  }); 

});






