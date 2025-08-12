$(document).ready(function() {

  // Logs - just BestBets for now
  $('.log-datatable').DataTable( {
    pageLength: 100,
    lengthMenu: [ [20, 50, 100, -1], [20, 50, 100, "All"] ],
    dom: '<"top"flip>',
    'aaSorting': []
  } );

  // Two tables on the My Borrowing Account page
  $('.loans-datatable').DataTable( {
    paging: false
  } );

  $('.requests-datatable').DataTable( {
    paging: false
  } );

  
} );


