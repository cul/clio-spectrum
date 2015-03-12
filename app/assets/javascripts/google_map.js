// Take care of requiring our own dependencies,
// so don't do this anywhere else!
//= require gmaps/google
//= require underscore-min


var aryMapStyles =  [
{
  featureType: "poi.business",
  elementType: "all",
  stylers: [
    {visibility: "off"}
  ]
}
];

function buildGoogleMap()
{
  handler = Gmaps.build('Google');
  
  handler.buildMap({ 
    provider: {styles:aryMapStyles},
    internal: {id: 'map'}}, function(){
    markers = handler.addMarkers($('#map').data('markers'));
    handler.bounds.extendWith(markers);
    handler.map.centerOn(new google.maps.LatLng(40.8078425, -73.9621477));
    handler.getMap().setZoom(17);
    google.maps.event.trigger(markers[($('#map').data('currentLocationIndex'))].serviceObject, 'click');
    var transitLayer = new google.maps.TransitLayer();
    transitLayer.setMap(handler.map.serviceObject);
  });

}

$(document).ready(function() {
  buildGoogleMap()
});
