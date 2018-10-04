// $ -> 
//   $('.search_option_action').click ->
//     # NEXT-836 - Can't uncheck multiple options at the same time
//     $('.busy').show()
//     window.location.href = $(this).attr('href')


$(document).ready(function() {

  $('.search_option_action').click(function(){
    // NEXT-836 - Can't uncheck multiple options at the same time
    $('.busy').show();
    window.location.href = $(this).attr('href');
  });


  $( ".validate-date-format" ).change(function() {
    raw = $(this).val()
    if (raw.length == 0) {
      $(this).removeClass('invalid-input');
      return;
    }
    // MM/YYYY is ok, although it won't pass the JS test below
    if ( raw.match( /^\d{1,2}\/\d\d\d\d$/ ) ) {
      $(this).removeClass('invalid-input');
      return;
    }

    testDate = new Date(raw);
    if (testDate instanceof Date  && ! isNaN(testDate)) {
      // filled in with valid date!
      $(this).removeClass('invalid-input');
      // console.log('ok');
    } else {
      // Not a valid date string?  Replace with empty string.
      $(this).addClass('invalid-input');
      // $(this).val('');
      // console.log('bad');
    }
  });


}); //ready
