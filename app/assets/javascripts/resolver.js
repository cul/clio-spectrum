
// NEXT-1852 - new resolver links in CLIO test

if (resolver_rewrite_javascript) {

  startTime = new Date();

  var anchors = document.getElementsByTagName('a');

  for (var i = 0; i < anchors.length; i++) {
    url = anchors[i].href

    old_resolver_url = 'http://www.columbia.edu/cgi-bin/cul/resolve?';
    new_resolver_url = 'https://resolver.library.columbia.edu/';

    //console.log("found:" + url)
    if (url.startsWith(old_resolver_url)) {
      //console.log("replacing:" + url)
      new_url = url.replace(old_resolver_url, new_resolver_url)
      anchors[i].href = new_url;
    }

  }


  endTime = new Date();
  timeElapsed = endTime - startTime;

  //console.log("Time Elapsed (s):" + (timeElapsed/1000) );

}


