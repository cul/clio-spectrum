
var bestBetsBloodhound;


// Given a URL to bounce to, 
// gather up anything we'd like to submit to logging,
// package it into a logdata json param,
// and return full URL to log-bounce endpoint
function logging_bounce_url(suggestion) {
  var datasource = $('#best_bets').data('datasource');
  var search     = $('#best_bets').data('q');
  var title      = suggestion.title;
  var keywords   = suggestion.keywords;
  var url        = suggestion.url;
  
  var logdata    = {
    "Datasource": datasource,
    "Search":     search,
    "Title":      title,
    "Keywords":   keywords,
    "URL":        url,
  };
  logdata = JSON.stringify(logdata);

  bounce_url = "/logs/bounce?" + 
               "set=" + encodeURIComponent("Best Bets") +
               "&url=" + encodeURIComponent(suggestion.url) +
               "&logdata=" + encodeURIComponent(logdata);

  // console.log("bounce_url=" + bounce_url);

  return bounce_url;
};


$(document).ready(function() {

  // retrieve data embedded on page
  var best_bets_url = $('#best_bets').data('url')

  // build Best Bets typeahead
  if (typeof(best_bets_url) == 'undefined') { return; }

  // Custom tokenizer - elminate all spaces, break on commas
  function concatter(str) {
    tokens = str ? str.replace(/ /g, '').split(/\,/) : [];
    // console.log('inside concatter str=['+str+'] tokens=['+tokens+']');
    return tokens;
    // return str ? str.replace(/ /g, '').split(/\,/) : [];
  };

  // (1) build the search engine
  bestBetsBloodhound = new Bloodhound({
    // queryTokenizer: Bloodhound.tokenizers.whitespace,
    queryTokenizer: concatter,

    // Look for the query value in any of the list of fields
    // datumTokenizer: Bloodhound.tokenizers.obj.whitespace('title', 'description', 'keywords'),
    // Nope.  The librarians need absolute control, so don't search on
    // what the user sees at all, only on the managed key search terms.
    // datumTokenizer: Bloodhound.tokenizers.obj.whitespace('keywords'),
    // Use the pre-cooked "tokens" - split on commas, spaces removed
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('tokens'),

    // Sort suggestions by their Title field, alphabetically
    sorter: function (a, b) {
      var stopwords = ['a', 'an', 'the'];
      var stripper = new RegExp('\\b('+stopwords.join('|')+')\\b', 'ig')
      var titleA = a.title.replace(stripper, '').trim();
      var titleB = b.title.replace(stripper, '').trim();
      var comparison = titleA.localeCompare(titleB);
      return comparison;
    },

    prefetch: {
      url: best_bets_url,
      cache: false,
      // cache: true,
      // "time in ms to cache, default 86400000 (1 day)" - doesn't work?
      // ttl: 1,
    }
    // for testing....
    // local: ['dog', 'pig', 'moose'],
    // local: [{title: 'dog'}, {title: 'pig'}, {title: 'moose'}],
  });  // new Bloodhound()



// });  // document.ready
// 
// $('.best-bets-typeahead').on('focus', function(e) {


  // inputBox = e.target;

  // if (inputBox.classList.contains('tt-input')) {
  //   // alert('tt-input already');
  //   return;
  // } else {
  //   // alert('no tt-input, adding...');
  // };

  // retrieve data embedded on page
  var best_bets_url = $('#best_bets').data('url')

  // build Best Bets typeahead
  if (typeof(best_bets_url) != 'undefined') {

    // (2) build the user interface
    $('.best-bets-typeahead').typeahead(
      {
        // How many typed characters trigger Best Bets suggestions?
        minLength: 3,
        hint: false,
      },
      {
         name: 'best-bets',
         source: bestBetsBloodhound,
         templates: {
          suggestion: function (data) {
            snippet = buildSnippet(data);
            return snippet;
          },
        },
        // How many best-bet suggestions should be displayed?
        limit: 7,
        display: 'title',
      }
    );  // .typeahead()

    // Before we open the typeahead, compare 'q' input field to 'q' URL param
    // If 'q' came from the URL, not the user, abort the typeahead
    $('.best-bets-typeahead').bind('typeahead:beforeopen', function(ev, suggestion) {
      // console.log('>> typeahead:beforeopen');
      query_input = ev.target.value;
      query_param = window.location.search
      if (query_param.includes("q=" + query_input)) {
        return false;
      }
    });

    // Before the destructive 'select' callback is called,
    // preserve the original search value in a data attribute.
    $('.best-bets-typeahead').bind('typeahead:beforeselect', function(ev, suggestion) {
      // console.log('>> typeahead:beforeselect triggered');
      $('#best_bets').data('q', ev.target.value);
    });

    // SELECT - OPEN URL IN NEW WINDOW
    $('.best-bets-typeahead').bind('typeahead:select', function(ev, suggestion) {
      // console.log('>> typeahead:select triggered');
      ev.preventDefault();

      var mouse_click = $( '.best-bets-typeahead' ).data( 'click' )
      // console.log("mouse_click:" +  mouse_click );
      $( '.best-bets-typeahead' ).data( 'click', false )
      // console.log("reset mouse_click:" +  $( '.best-bets-typeahead' ).data( 'click' ) );

      // if user has decided to use a best-best (click/enter), then...
      if ('url' in suggestion && suggestion.url.length > 0) {
        // (1) clear out the input field
        $(this).typeahead('val', '');

        // (2) jump to the URL in a new window
        // IF this is a FIREBOX KEYBOARD event...
        // console.log('one');
        if (navigator.userAgent.indexOf("Firefox") !== -1){
          // console.log('two: mouse_click=['+mouse_click+']');
          if (mouse_click != true) {
            // console.log('three');
            // alert("Firefox, Keyboard");
            bestBetModal(suggestion);
            return;
          };
        };

        // ELSE, anything else, just a simple window.open
        // window.open(suggestion.url, '_blank');
        bounce_url = logging_bounce_url(suggestion);
        window.open(bounce_url, '_blank');
      }

    }  );

    // CURSORCHANGE (up/down within suggestion list)
    // - DON'T REPLACE USER INPUT WITH TT HINT VALUE
    $('.best-bets-typeahead').bind('typeahead:cursorchange', function(ev, suggestion) {
      // console.log('>> typeahead:cursorchange');

      // reset the input box value with the original value (not the suggestion)
      ev.target.value = $(this).typeahead('val');
    });



    // DEBUGGING
    // $('.best-bets-typeahead').bind('typeahead:render', function(ev, suggestion) {  console.log('>> typeahead:render'); });
    // $('.best-bets-typeahead').bind('typeahead:active', function(ev, suggestion) {  console.log('>> typeahead:active'); });
    // $('.best-bets-typeahead').bind('typeahead:idle', function(ev, suggestion) {  console.log('>> typeahead:idle'); });
    // $('.best-bets-typeahead').bind('typeahead:open', function(ev, suggestion) {  console.log('>> typeahead:open'); });
    // $('.best-bets-typeahead').bind('typeahead:close', function(ev, suggestion) { console.log('>> typeahead:close'); });
    // $('.best-bets-typeahead').bind('typeahead:change', function(ev, suggestion) {  console.log('>> typeahead:change'); });

    // "beforeXYZ" events fire before each XYZ event.
    $('.best-bets-typeahead').bind('typeahead:beforeautocomplete', function(ev, suggestion) {
      // console.log('>> typeahead:beforeautocomplete');
      // console.log('ev.target.value=' + ev.target.value);
      // console.log('$(this).typeahead("val")=' + $(this).typeahead('val'));
      // Prevent regular autocomplete from replacing input query
      return false;
    });

    // $('.best-bets-typeahead').bind('typeahead:autocomplete', function(ev, suggestion) {  console.log('>> typeahead:autocomplete'); });

    // // Initializing the Typeahead looses element focus
    // setTimeout(function(){
    //     $('.best-bets-typeahead.tt-input').focus();
    // }, 1);

  }  // if typeof(best_bets_url...


  // $('.best-bets-typeahead').bind('typeahead:beforeopen', function (event) {
  //     event.preventDefault();
  // });


  // nice formatting of each best-bet suggestion
  function buildSnippet(data) {
    var title = "<span class='best-bets-title'>" + data.title + "</span>\n";
    var description = "";
    if (typeof(data.description) != 'undefined' && data.description.length > 0) {
      var description = "<span> - " + data.description + "</span>\n";
    }
    var url   = "";
    if (typeof(data.url) != 'undefined' && data.url.length > 0) {
      url = "<br><a href='#'>" + data.url + "</a>\n";
    }
    var snippet = "<div class='best-bets-snippet' onclick='$(\".best-bets-typeahead\").data(\"click\",true);'>\n" + title + description + "\n" + url + "</div>\n";
    return snippet;
  };



});  // .best-bets-typeahead').on("input"...

