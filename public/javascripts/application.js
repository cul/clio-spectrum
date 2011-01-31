
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

function update_holdings_info(bibids) {
 url = 'http://ldpdmac01.cul.columbia.edu:3100/holdings/fetch/' + bibids.join("/");

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
    selector = $("img.bookjacket[src*='images/spacer.png'].isbn_" + isbn);
    isbn_data = data[isbn];
    console.log(data);
    console.log(isbn_data);
    console.log(selector.length);
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

      if (isbn_data.preview != "noview") {
        gbs_cover.children(".gbs_preview").show();
        gbs_cover.find(".gbs_preview_link").attr("href", isbn_data.preview_url);
      }
      
    }
  }

}

