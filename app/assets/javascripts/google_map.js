//= require gmaps/google
//= require underscore

handler = Gmaps.build('Google');
handler.buildMap({ internal: {id: 'map'}}, function(){
  markers = handler.addMarkers($('#map').data('markers'));
  handler.bounds.extendWith(markers);
  handler.map.centerOn(markers[0]); 
  handler.getMap().setZoom(18);
});

