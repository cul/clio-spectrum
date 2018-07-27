
$(document).ready(function() {

  // retrieve data embedded on page
  var best_bets_url = $('#best_bets').data('url')

  // NEXT-1499 - "drop down, no panel"
  // // build Best Bets panel
  // var q = $('#best_bets').data('query')
  // if (typeof(q) != 'undefined'  &&  q.length > 2) {
  //   $.get('/best_bets/hits?q=' + q, function(data) {
  //     if (data.length > 0) {
  //       $('#best_bets_hits').append("<em class='small'>top suggestions...</em>");
  //       $('#best_bets_hits').append(data);
  //       $('#best_bets_hits').slideDown(1000);
  //     };
  //   });
  // };

  // build Best Bets typeahead
  if (typeof(best_bets_url) != 'undefined') {

    // (1) build the search engine
    var bestBets = new Bloodhound({
      queryTokenizer: Bloodhound.tokenizers.whitespace,
      // Look for the query value in any of the list of fields
      // datumTokenizer: Bloodhound.tokenizers.obj.whitespace('title', 'description', 'keywords'),
      // or search a single concattenated field?
      // datumTokenizer: Bloodhound.tokenizers.obj.whitespace( 'haystack' ),
      // Nope, now they only want Title and Keywords
      datumTokenizer: Bloodhound.tokenizers.obj.whitespace('title', 'keywords'),

      prefetch: {
        url: best_bets_url,
        cache: false,
        // "time in ms to cache, default 86400000 (1 day)" - doesn't work?
        ttl: 1,
      }
      // for testing....
      // local: ['dog', 'pig', 'moose'],
      // local: [{title: 'dog'}, {title: 'pig'}, {title: 'moose'}],
    });

    // bestBets.initialize(true);


    // (2) build the user interface
    $('.best_bets_typeahead').typeahead(
      { 
        // How many typed characters trigger Best Bets suggestions?
        minLength: 4,
        hint: false,
      }, 
      {  
        name: 'best-bets',
        source: bestBets,
        templates: {
          suggestion: function (data) {
            snippet = buildSnippet(data);
            return snippet;
          },
        },
        display: 'title',
      }
    );
  }

  // SELECT - OPEN URL IN NEW WINDOW
  $('.best_bets_typeahead').bind('typeahead:select', function(ev, suggestion) { 

    // console.log('>> typeahead:select triggered'); 
    // console.log("val is now set to:" + $(this).typeahead('val')  );
    // console.log("ev.target.value is now set to:" + ev.target.value);
    // console.log("ev.target.saved_value is now set to:" + ev.target.saved_value);
    // console.log(suggestion);

    // $(this).typeahead('val', ev.target.saved_value);
    // ev.target.value = ev.target.saved_value

    // if user has decided to use a best-best (click/enter), then...
    if ('url' in suggestion && suggestion.url.length > 0) {
      // (1) clear out the input field
      $(this).typeahead('val', '');
      // (2) jump to the URL in a new window
      window.open(suggestion.url, '_blank');
    }
    
    // console.log("** manually closing typeahead **")
    // $(this).typeahead('close');
    // console.log("** done **")

  }  );

  // CURSORCHANGE - DON'T REPLACE USER INPUT WITH TT HINT VALUE
  $('.best_bets_typeahead').bind('typeahead:cursorchange', function(ev, suggestion) {
    // console.log('>> typeahead:cursorchange'); 
    // console.log(ev);
    // console.log("val is now set to:" + $(this).typeahead('val')  );
    // console.log("ev.target.value is now set to:" + ev.target.value);
    ev.target.value = $(this).typeahead('val');
  });


  // Experiments w/saving user's input before TT replaces it.
  // $('.best_bets_typeahead').bind('typeahead:beforeselect', function(ev, suggestion) { 
  //   console.log('>> typeahead:beforeselect triggered'); 
  //   console.log("val is now set to:" + $(this).typeahead('val')  );
  //   console.log("ev.target.value is now set to:" + ev.target.value);
  //   ev.target.saved_value = ev.target.value;
  // }  );


  // DEBUGGING
  // $('.best_bets_typeahead').bind('typeahead:close', function(ev, suggestion) {
  //   console.log('>> typeahead:close'); 
  // });
  // $('.best_bets_typeahead').bind('typeahead:active', function(ev, suggestion) {  console.log('>> typeahead:active'); });
  // $('.best_bets_typeahead').bind('typeahead:open', function(ev, suggestion) {  console.log('>> typeahead:open'); });
  // $('.best_bets_typeahead').bind('typeahead:change', function(ev, suggestion) {  console.log('>> typeahead:change'); });
  // $('.best_bets_typeahead').bind('typeahead:render', function(ev, suggestion) {  console.log('>> typeahead:render'); });
  // $('.best_bets_typeahead').bind('typeahead:autocomplete', function(ev, suggestion) {  console.log('>> typeahead:autocomplete'); });
  // $('.best_bets_typeahead').bind('blurred', function(ev, suggestion) {  console.log('>> blurred'); });
  // $('.best_bets_typeahead').bind('typeahead:onBlurred', function(ev, suggestion) {  console.log('>> typeahead:onBlurred'); });
  // $('.best_bets_typeahead').bind('typeahead:_onBlurred', function(ev, suggestion) {  console.log('>> typeahead:_onBlurred'); });



  // nice formatting of each best-bet suggestion
  function buildSnippet(data) {
    var title = "<span>" + data.title + "</span>\n";
    var description = "";
    if (typeof(data.description) != 'undefined' && data.description.length > 0) {
      var description = "<span> - " + data.description + "</span>\n";
    }
    var url   = "";
    if (typeof(data.url) != 'undefined' && data.url.length > 0) {
      url = "<br><a href='" + data.url + "'>" + data.url + "</a>\n";
    }
    var snippet = "<div class='best-bets-snippet'>\n" + title + description + "\n" + url + "</div>\n";
    return snippet;
  };

});

