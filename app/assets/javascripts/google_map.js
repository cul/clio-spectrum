//= require gmaps/google
//= require underscore

handler = Gmaps.build('Google');
handler.buildMap({ internal: {id: 'map'}}, function(){
  markers = handler.addMarkers($('#map').data('markers'));
  handler.bounds.extendWith(markers);
  handler.map.centerOn(new google.maps.LatLng(40.8078425, -73.9621477));
  handler.getMap().setZoom(17);
  google.maps.event.trigger(markers[($('#map').data('currentLocationIndex'))].serviceObject, 'click');
});

