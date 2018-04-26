
$(document).ready(function() {

  // retrieve data embedded on page
  var best_bets_url = $('#best_bets').data('url')
  var q = $('#best_bets').data('query')

  // build Best Bets panel
  if (typeof(q) != 'undefined'  &&  q.length > 2) {
    $.get('/best_bets/hits?q=' + q, function(data) {
	    if (data.length > 0) {
        $('#best_bets_hits').append(data);
        $('#best_bets_hits').slideDown(1000);
      };
	  });
	};

	// build Best Bets typeahead
  if (typeof(best_bets_url) != 'undefined') {

		// (1) build the search engine
		var bestBets = new Bloodhound({
		  queryTokenizer: Bloodhound.tokenizers.whitespace,
			// Look for the query value in any of the list of fields
		  datumTokenizer: Bloodhound.tokenizers.obj.whitespace('title', 'description', 'keywords'),
			// or search a single concattenated field?
		  // datumTokenizer: Bloodhound.tokenizers.obj.whitespace( 'haystack' ),

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
			{ minLength: 2,
	  	}, 
			{	name: 'best-bets',
				source: bestBets,
				templates: {
				  header: '<h4>Best Bets</h4>',
		      suggestion: function (data) {
			      snippet = buildSnippet(data);
			      return snippet;
	  		  },
		  	},
				display: 'title',
		  }
		);
	}

  // nice formatting of each search suggestion
  function buildSnippet(data) {
	  var title = "<strong>" + data.title + "</strong>\n";
	  var url   = "";
	  if (typeof(data.url) != 'undefined' && data.url.length > 0) {
		  url = "<br><a href='" + data.url + "'>" + data.url + "</a>\n";
  	}
    var snippet = "<div>\n" + title + data.description + "\n" + url + "</div>\n";
    return snippet;
  };

});

