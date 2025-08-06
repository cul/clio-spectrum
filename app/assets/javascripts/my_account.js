

$(document).ready(function() {
  $('#select-all').on('change', function() {
    $('input[name="loan_ids[]"]').prop('checked', this.checked);
  });
});


