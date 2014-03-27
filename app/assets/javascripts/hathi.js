/*
 * Copied from Voyager, 9/13, with minimal changes.
 *
 * Full View examples:  513297, 1862548, 2081553
 *
 * Limited examples:  70744, 4043762, 2517624
 */

/**
* http://www.hathitrust.org/bib_api
*/

var dataArrivedHathi="false";
var currentBibKeyValue='';

function parseResponse(bookInfo) 
{
  // alert("YES:  parseResponse: " + bookInfo);
  // Actually, this is done in the CSS by default
  //  // Hide the row until we have something to display
  // document.getElementById('hathi_holdings').style.display = 'none';

  var hathiDiv = document.getElementById('hathidata');

  var records = bookInfo.records;
  var items   = bookInfo.items;
  var message = "";
  var recordId = "";
  var url = "";
  var usRightsString = "";

  var paragraph = document.createElement('p');

  /* You only get here if you have something to display
  if ( records.length == 0) {
    message = "No hathi trust record for this book";
    paragraph.appendChild(document.createTextNode(message));
    hathiDiv.appendChild(paragraph);
    return;
  } 

  if ( items.length == 0) {
    message = "Hathi record found, but no item.  This should not happen.";
    paragraph.appendChild(document.createTextNode(message));
    hathiDiv.appendChild(paragraph);
    return;
  } 
  */
  

  // Gather up some useful data
  for (i in records) {
    recordId = i;
    url = records[recordId].recordURL;
  }

  for (i in items)
  {
    // remember the best rights yet (none, limited, full)
      if ( (items[i].usRightsString == "Full view") ||
	   (items[i].usRightsString == "Full View") ) {
      usRightsString = items[i].usRightsString;
    }
    if (items[i].usRightsString != "Full View") {
      if (usRightsString == "") { usRightsString = items[i].usRightsString; }
    }
  }

  var hathiURL = document.createElement("a");
  hathiURL.href = url;
  hathiURL.setAttribute("target", "_hathi");  // opens in a new window
  hathiDiv.appendChild(hathiURL);

  // paragraph.innerHTML = "Hathi record " + recordId + ": " + usRightsString;
  // hathiURL.appendChild(paragraph);
  // Cleaner message?  Better HTML?
  textNode = document.createTextNode(usRightsString + " access at Hathi Trust");
  hathiURL.appendChild(textNode);


  // now display row
  // document.getElementById('hathi_holdings').style.display = '';
  // document.getElementById('hathiBooks').style.display = 'block';
  // but in the jQuery way - it's so much easier
  $('#hathi_holdings').show()

}

function hathiBookSearch()
{
    // var hathiDiv = document.getElementById('hathidata');

   // Show a "Loading..." indicator.
   // var paragraph = document.createElement('p');
   // paragraph.appendChild(document.createTextNode('Loading Hathi data...'));
   // hathiDiv.appendChild(paragraph);
   
   // Delete any previous JavaScript Object Notation queries.
   var jsonScript = document.getElementById("hathiScript");
   if (jsonScript) {
      jsonScript.parentNode.removeChild(jsonScript);
   }
   
   // Pluck out our data elements, search appropriately
   // isbn and issn do not appear in the same record so a single handler is possible
   if(document.getElementById('hisbn'))
       {
	   doBookScriptsHathi('hisbn','isnHandlerHathi');
       }
   else if(document.getElementById('hissn'))
       {
	   doBookScriptsHathi('hissn','isnHandlerHathi');
       }
   else if(document.getElementById('hoclc'))
       {
	   doBookScriptsHathi('hoclc','oclcHandlerHathi');
       }
   else if(document.getElementById('hlccn'))
       {
	   doBookScriptsHathi('hlccn','lccnHandlerHathi');
       }

}

function doBookScriptsHathi(bibKey,handler)
{
	// alert("doing bibKey " + bibKey)
    // Add a script element with the src as the user's Hathi API query.
    // the callback funtion is also specified as a URI argument.

    // Voyage was using this... 
    // http://catalog.hathitrust.org/api/volumes/brief/oclc/649417.json?callback=foo
    // but it doesn't look like Hathi does it this way?  Did it change?
    // var lookupURL = "http://catalog.hathitrust.org/api/volumes/brief/" + 
    //                escape(document.getElementById(bibKey).value) + 
    //                ".json?callback=" + handler;

    // Based on current (9/13) docs, do this:
    // http://catalog.hathitrust.org/api/volumes/brief/json/oclc:649417?callback=foo
    currentBibKeyValue = document.getElementById(bibKey).value;
    var lookupURL = "http://catalog.hathitrust.org/api/volumes/brief/json/" + 
                   escape(currentBibKeyValue) + 
                   "?callback=" + handler;

    var scriptElement = document.createElement("script");
    scriptElement.setAttribute("id", "hathiScript");
    scriptElement.setAttribute("src", lookupURL);
    scriptElement.setAttribute("type", "text/javascript");

    // make the request to Hathi booksearcsh
    document.documentElement.firstChild.appendChild(scriptElement);

}

function isnHandlerHathi(bookInfo)
{
    var records = bookInfo[currentBibKeyValue].records;
    //if ( records.length != 0 ) {
    if ( ! isEmpty(records) ) {
	dataArrivedHathi="true";
	parseResponse(bookInfo[currentBibKeyValue]);
    }

    if(dataArrivedHathi=='false')
	{
	    if(document.getElementById('hoclc'))
		{
		    doBookScriptsHathi('hoclc','oclcHandlerHathi');
		}
	    else if(document.getElementById('hlccn'))
		{
		    doBookScriptsHathi('hlccn','lccnHandlerHathi');
		}
	}
}

function oclcHandlerHathi(bookInfo)
{
	// alert("in oclcHandlerHathi, bookInfo=" + bookInfo)
    var records = bookInfo[currentBibKeyValue].records;
    // alert("records="+records)
    //if ( records.length != 0 ) {
    if ( ! isEmpty(records) ) {
	dataArrivedHathi="true";
	parseResponse(bookInfo[currentBibKeyValue]);
    }

   if(dataArrivedHathi=='false')
   {
      if(document.getElementById('hlccn'))
      {
         doBookScriptsHathi('hlccn','lccnHandlerHathi');
      }
   }
}

function lccnHandlerHathi(bookInfo)
{
    var records = bookInfo[currentBibKeyValue].records;
    //if ( records.length != 0 ) {
    if ( ! isEmpty(records) ) {
	dataArrivedHathi="true";
	parseResponse(bookInfo[currentBibKeyValue]);
    }

}

// the api returns an empty object if there are no results
function isEmpty(obj) {
    for (var prop in obj) {
	if (obj.hasOwnProperty(prop)) {
	    return false;
	}
    }
    return true;
}



$(document).ready(function() {
  hathiBookSearch()
});


