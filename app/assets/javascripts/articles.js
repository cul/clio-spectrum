// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(document).ready(function() {
  $('.facet_action').click( function(event) {
    window.location.href = $(this).attr('href');
  });
});
