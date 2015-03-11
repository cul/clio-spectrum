//= require gmaps/google
//= require underscore

var mapExists = document.getElementById("map"); 
if(mapExists){
  handler = Gmaps.build('Google');
  var aryMapStyles =  [
  {
    featureType: "poi.business",
    elementType: "all",
    stylers: [
      {visibility: "off"}
    ]
  }
  ];
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
