
var bestBetsBloodhound;

$(document).ready(function() {

  // retrieve data embedded on page
  var best_bets_url = $('#best_bets').data('url')

  // build Best Bets typeahead
  if (typeof(best_bets_url) == 'undefined') { return; }

  // (1) build the search engine
  bestBetsBloodhound = new Bloodhound({
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    // Look for the query value in any of the list of fields
    // datumTokenizer: Bloodhound.tokenizers.obj.whitespace('title', 'description', 'keywords'),
    // Nope.  The librarians need absolute control, so don't search on
    // what the user sees at all, only on the managed key search terms.
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('keywords'),

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
      cache: true,
      // "time in ms to cache, default 86400000 (1 day)" - doesn't work?
      // ttl: 1,
    }
    // for testing....
    // local: ['dog', 'pig', 'moose'],
    // local: [{title: 'dog'}, {title: 'pig'}, {title: 'moose'}],
  });

});  // document.ready




$('.best_bets_typeahead').on("input", function(e) {

  inputBox = e.target;

  if (inputBox.classList.contains('tt-input')) {
    // alert('tt-input already');
    return;
  } else {
    // alert('no tt-input, adding...');
  };
  
  // retrieve data embedded on page
  var best_bets_url = $('#best_bets').data('url')

  // build Best Bets typeahead
  if (typeof(best_bets_url) != 'undefined') {

    // (2) build the user interface
    $('.best_bets_typeahead').typeahead(
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
    );

    // SELECT - OPEN URL IN NEW WINDOW
    $('.best_bets_typeahead').bind('typeahead:select', function(ev, suggestion) { 
      // console.log('>> typeahead:select triggered'); 

      var mouse_click = $( '.best_bets_typeahead' ).data( 'click' )
      // console.log("mouse_click:" +  mouse_click );
      $( '.best_bets_typeahead' ).data( 'click', '' )

      // if user has decided to use a best-best (click/enter), then...
      if ('url' in suggestion && suggestion.url.length > 0) {
        // (1) clear out the input field
        $(this).typeahead('val', '');
        
        // (2) jump to the URL in a new window
        // IF this is a Firefox Keyboard event...
        console.log('one');
        if (navigator.userAgent.indexOf("Firefox") !== -1){
          console.log('two: mouse_click=['+mouse_click+']');
          if (mouse_click == undefined) {
            console.log('three');
            alert("Firefox, Keyboard");
            return;
          };
        };
        
        // ELSE, anything else, just a simple window.open
        window.open(suggestion.url, '_blank');
      }
    
    }  );

    // CURSORCHANGE (up/down within suggestion list) 
    // - DON'T REPLACE USER INPUT WITH TT HINT VALUE
    $('.best_bets_typeahead').bind('typeahead:cursorchange', function(ev, suggestion) {
      console.log('>> typeahead:cursorchange'); 
    
      // reset the input box value with the original value (not the suggestion)
      ev.target.value = $(this).typeahead('val');
    });



    // DEBUGGING
    // $('.best_bets_typeahead').bind('typeahead:close', function(ev, suggestion) {
    //   console.log('>> typeahead:close'); 
    // });
    // $('.best_bets_typeahead').bind('typeahead:active', function(ev, suggestion) {
    //   console.log('>> typeahead:active');
    //   ev.preventDefault();
    // });

    // $('.best_bets_typeahead').bind('typeahead:open', function(ev, suggestion) {  console.log('>> typeahead:open'); });
    // $('.best_bets_typeahead').bind('typeahead:change', function(ev, suggestion) {  console.log('>> typeahead:change'); });


    // Initializing the Typeahead looses element focus
    setTimeout(function(){
        $('.best_bets_typeahead.tt-input').focus();
    }, 1);

  }


  // $('.best_bets_typeahead').bind('typeahead:beforeopen', function (event) {
  //     event.preventDefault();
  // });


  // nice formatting of each best-bet suggestion
  function buildSnippet(data) {
    var title = "<span>" + data.title + "</span>\n";
    var description = "";
    if (typeof(data.description) != 'undefined' && data.description.length > 0) {
      var description = "<span> - " + data.description + "</span>\n";
    }
    var url   = "";
    if (typeof(data.url) != 'undefined' && data.url.length > 0) {
      url = "<br><a href='#'>" + data.url + "</a>\n";
    }
    var snippet = "<div class='best-bets-snippet' onclick='$(\".best_bets_typeahead\").data(\"click\",true);'>\n" + title + description + "\n" + url + "</div>\n";
    return snippet;
  };

});

