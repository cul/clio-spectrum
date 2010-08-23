// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function update_holdings_info(url,bibids) {
  for (bibid in bibids) {
    $.getJSON(url + "?bibid=" + bibids[bibid], function(data) {
      for (key in data.holdingsId) {
        selector = "img.availability.holding_" + key;  
        $(selector).attr("src", RAILS_ROOT + "/images/icons/"+data.holdingsId[key]+".png");
      }
    });
  }
}
