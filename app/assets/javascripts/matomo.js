// Matomo - NEXT-1862
var _paq = window._paq = window._paq || [];
/* tracker methods like "setCustomDimension" should be called before "trackPageView" */
_paq.push(['trackPageView']);
_paq.push(['enableLinkTracking']);
(function() {
  var u="https://columbia-libraries.matomo.cloud/";
  _paq.push(['setTrackerUrl', u+'matomo.php']);
  if ($("body").data('environment') == 'clio_prod') {
    _paq.push(['setSiteId', '9']);
  } else {
    _paq.push(['setSiteId', '10']);
  }
  var d=document, g=d.createElement('script'), s=d.getElementsByTagName('script')[0];
  g.async=true; g.src='//cdn.matomo.cloud/columbia-libraries.matomo.cloud/matomo.js'; s.parentNode.insertBefore(g,s);
})();
