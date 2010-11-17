
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
            new_button_text = '<img alt="Add to Folder" height="22" src="/images/icons/24-book-blue-add.png" width="22" /><span class="folder_link_text">Add to folder</span>';
          }else{
            folder_num = parseInt($("#folder_number").text()) + 1
            notice_text = title + " added to your folder.";
            new_form_action = "/folder/destroy";
            new_button_text = '<img alt="Remove from Folder" height="22" src="/images/icons/24-book-blue-remove.png" width="22" /><span class="folder_link_text">Remove from folder</span>';
          }
          $("#folder_number").text(folder_num);
          form.attr("action",new_form_action);
          form.children("a.folder_link_submit").html(new_button_text);
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
    for (key in data) {
      selector = "img.availability.holding_" + key;  
      $(selector).attr("src", RAILS_ROOT + "/images/"+data[key]);
    }
  });
}

function update_book_jackets(isbns, data) {
  for (index in isbns) {
    isbn = isbns[index];
    selector = $("img.bookjacket[src*='/images/spacer.png'].isbn_" + isbn);
    
    if (selector.length > 0 && data[isbn]) {
      selector.attr("src", data[isbn]["thumbnail_url"]);
      selector.parents(".google_cover").show();
      selector.parents(".cover_with_jacket").children(".fake_cover").hide();
    }
  }

}
