
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


// UNIVERSAL TRACKING CODE FROM GA WEBSITE

(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
})(window,document,'script','//www.google-analytics.com/analytics.js','ga');

ga('create', google_analytics_web_property_id, 'columbia.edu');
ga('send', 'pageview');


// Click-Tracking as GA Events, based on:
//   http://www.lunametrics.com/blog/2013/07/02/jquery-event-tracking

$(document).ready(function() {
 
  $("a.linkout").each(function() {
    var href   = $(this).attr("href");
    var target = $(this).attr("target");
    var text   = $(this).text();

    var category = $(this).data("ga-category") || "Outbound Link";
    var action = $(this).data("ga-action") || "Click";
    var label = $(this).data("ga-label") || text;

    $(this).click(function(event) { // when someone clicks these links

      event.preventDefault(); // don't open the link yet

      // _gaq.push(["_trackEvent", category, action, label]); // create a custom event
      // _trackEvent(category, action, label)
      ga('send', 'event', category, action, label);

      setTimeout(function() { // now wait 300 milliseconds...
        window.open(href,(!target ? "_blank" : target)); // ...and open in new blank window
      },300);
    });
  });

  // $('.copy_tracker').bind({
  //   copy : function() {
  //     alert(this)
  //   }
  // });

  // FAIL - too restrictive, doesn't ever really get triggered
  $(".call_number").bind('copy', function() {
    alert('copy call number only')
    return false;
  }); 


  // GENERIC - DOCUMENT DETAILS COPIED
  $("#documents .result").bind('copy', function() {
    alert('copy single document details')
    return false;
  }); 

  // FAIL - never seems to get called?
  $("#documents").bind('copy', function() {
    alert('copy multiple document details')
    return false;
  }); 


});

// $('.cak').bind({
//   copy : function() {
//     alert(this)
//   }
// });


// Track copied content adapted from Onderweg & Tim Down by Robert Kingston - http://www.optimisationbeacon.com/
// Get Selection Text function by Tim Down - http://stackoverflow.com/a/5379408/458627
// function getSelectionText() {
//     var e = "";
//     if (window.getSelection) {
//         e = window.getSelection().toString()
//     } else if (document.selection && document.selection.type != "Control") {
//         e = document.selection.createRange().text
//     }
//     return e
// }
// $(document.body).bind("copy cut paste", function (e) {
//   var content = getSelectionText();
//   var contentClean = content.substring(0, 499).replace(/\\(n|r\\n|r)/gm, "\\n "); // Represent new lines
//   var length = content.length;
//   alert(contentClean);
//   // _gaq.push(['_trackEvent', 'clipboard', e.type+' location: '+document.location.pathname, contentClean, length, true]);
// });

// $('div.title').onClick(alert('click'));





