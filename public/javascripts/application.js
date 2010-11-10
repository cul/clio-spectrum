
//function for adding items to your folder with Ajax
$(document).ready(function() {
	// each form for adding things into the folder.
	$("form.addFolder, form.deleteFolder").each(function() {
		var form = $(this);
    // We wrap the control on the folder page w/ a special element classed so we know not to
		// attach the jQuery function.  The reason is we want the solr response to refresh so that
		// pagination as properly udpated.
		if(form.parent(".in_folder").length == 0){
			form.children("a.folder_link_submit").click(function() {
				$.post(form.attr("action") + '?id=' + form.children("input[name=id]").attr("value"), function(data) {
					var title = form.attr("title");
					var folder_num, notice_text, new_form_action, new_button_text
					if(form.attr("action") == "/folder/destroy") {
						folder_num = parseInt($("#folder_number").text()) - 1;
						notice_text = title + " removed from your folder."
						new_form_action = "/folder";
						new_button_text = "Add to folder"
					}else{
						folder_num = parseInt($("#folder_number").text()) + 1
						notice_text = title + " added to your folder.";
						new_form_action = "/folder/destroy";
						new_button_text = "Remove from folder";
					}
				  $("#folder_number").text(folder_num);
					form.attr("action",new_form_action);
					form.children("a.folder_link_submit").text(new_button_text);
				});
				return false;
			});
	  }
	});	
});

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
      selector = $("img.bookjacket.isbn_" + key);
      
      if (selector.length > 0) {
        selector.attr("src", data[key]);
        selector.parents(".google_cover").show();
        selector.parents(".cover_with_jacket").children(".fake_cover").hide();
      }
    }
  });
}
