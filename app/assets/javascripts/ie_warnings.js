$(document).ready(function() {
  
  // alert("testing AAA")

  if ( navigator.userAgent.match(/MSIE ([0-9]+)\./) ) {

    if (RegExp.$1 <= 9) {
      // alert("old browser: MSIE " + RegExp.$1);
      
      firefox = '<a href="http://www.mozilla.org/en-US/firefox/new/">Firefox</a>'
      chrome  = '<a href="https://www.google.com/intl/en/chrome/browser/">Chrome</a>'
      safari  = '<a href="http://www.apple.com/safari/">Safari</a>'
      msie    = '<a href="http://windows.microsoft.com/en-us/internet-explorer/ie-10-worldwide-languages">Internet Explorer (IE) 10</a>'
      
      $('#outer-container').prepend('<div class="alert"><b>Warning:</b> Your browser is not fully supported. Please use the latest version of one of our fully supported browsers: ' + firefox + ', ' + chrome + ', ' + safari + ', or ' + msie + '. IE 9 is not fully supported and will only offer basic functionality.</div>');
    }

  }

}); //ready

