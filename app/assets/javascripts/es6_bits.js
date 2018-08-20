

function bestBetModal(suggestion) {
  bounce_url = "/r.html#" + encodeURIComponent(suggestion.url);
  
  // Build the html for a bootstrap modal
  modalDialog = `
    <div class="modal-dialog">
      <div class="modal-content">
        <div class="modal-body">
  
          <p>Follow link to resource:</p>
  
          <form action="${bounce_url}" target="_blank" onsubmit="$('#best-bets-modal').close();">
            <input id="best_bets_goto" type="submit" value="${suggestion.url}" />
          </form>
  
          <p>Links will open in a new window.</p>
  
        </div>
      </div>
    </div>
  `;
  
  // attach the HTML of the modal to the page
  document.getElementById('best-bets-modal').innerHTML = modalDialog;
  
  // open the modal
  $('#best-bets-modal').modal();
  
  // focus on the "go to" button on the modal
  $('#best-bets-modal').on('shown.bs.modal', function () {
    $('#best_bets_goto').focus();
  })
};


