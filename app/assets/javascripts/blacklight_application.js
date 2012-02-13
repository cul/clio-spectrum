function update_holdings_info(bibids) {
 url = 'http://rossini.cul.columbia.edu/voyager_backend/holdings/fetch/' + bibids.join("/");

  $.getJSON(url, function(data) {
    for (bib in data) {
      for (holding in data[bib].holdings) {

        selector = "img.availability.holding_" + holding;  
        $(selector).attr("src", RAILS_ROOT + "/images/icons/"+data[bib].holdings[holding].status+".png");
      }
    }
  });
}

function update_book_jackets(isbns, data) {
  for (index in isbns) {
    isbn = isbns[index];
	isbn_name = isbn.replace(/:/, '')
    selector = $("img.bookjacket[src*='assets/spacer'].isbn_" + isbn_name);
    isbn_data = data[isbn];
    if (selector.length > 0 && isbn_data) {
    
      selector.parents("#show_cover").show();
      gbs_cover = selector.parents(".gbs_cover");
      
      if (isbn_data.thumbnail_url) {
        selector.attr("src", isbn_data.thumbnail_url.replace(/zoom\=5/,"zoom=1"));
        selector.parents(".book_cover").find(".fake_cover").hide();
        gbs_cover.show();
      }



      $("li.gbs_info").show();
      $("a.gbs_info_link").attr("href", isbn_data.info_url);
      console.log(isbn_data);
      if (isbn_data.preview != "noview") {
        gbs_cover.find(".gbs_preview").show();
        gbs_cover.find(".gbs_preview_link").attr("href", isbn_data.preview_url);
        
        gbs_cover.find(".gbs_search_form").attr("action", isbn_data.preview_url).show();
		if (isbn_data.preview == "partial") {
			gbs_cover.find(".gbs_preview_partial").show();
      
		}
		if (isbn_data.preview == "full") {
			gbs_cover.find(".gbs_preview_full").show();
		}
      }
      
    }
  }

}

$(document).ready(function() {
  $('.facet_toggle').bind('click', function() {
    window.location =  this.getAttribute('href');
  });
});
