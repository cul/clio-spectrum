
$(document).ready(function() {
  $("a[rel='popover']").popover();
  $('.facet_toggle').bind('click', function() {
    window.location =  this.getAttribute('href');
  });
});
