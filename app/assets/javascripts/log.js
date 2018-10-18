$(document).ready(function() {
  $('.log-datatable').DataTable( {
    pageLength: 100,
    lengthMenu: [ [20, 50, 100, -1], [20, 50, 100, "All"] ],
    dom: '<"top"flip>',
    'aaSorting': []
  } );
  
} );


