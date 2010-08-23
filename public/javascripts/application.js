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
