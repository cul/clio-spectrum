// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function update_holdings_info(url,bibids) {
  bibidstring = '?'

  for (i in bibids) {
    bibidstring += "bibid[]=" + bibids[i] + "&";
  }
  
  $.getJSON(url + bibidstring, function(data) {
    for (key in data.holdingsId) {
      selector = "img.availability.holding_" + key;  
      $(selector).attr("src", RAILS_ROOT + "/images/icons/"+data.holdingsId[key]+".png");
    }
  });
}

function update_book_jackets(url, docs) {
  docstring ='?'

  for (i in docs) {
    docstring += "isbns[]=" + docs[i] + "&";
  }

  $.getJSON(url + docstring, function(data) {
    
    for (key in data) {
      selector = "img.bookjacket.isbn_" + key;
      $(selector).attr("src", data[key]);

    }
  });
}
