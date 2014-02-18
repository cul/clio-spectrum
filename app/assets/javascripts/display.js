

function toggle_teaser (target) {
  $(target).toggleClass('icon-resize-small');
  $(target).prev().toggle();
}


// Fix broken menus on IOS 5?  Doesn't seem to work.
// http://stackoverflow.com/questions/12190783
// $('body').on('touchstart.dropdown', '.dropdown-menu', function (e) { 
//     e.stopPropagation(); 
// });

// $('body')
// .on('touchstart.dropdown', '.dropdown-menu', function (e) { e.stopPropagation(); })
// .on('touchstart.dropdown', '.dropdown-submenu', function (e) { e.preventDefault(); });


// Another form of this... also doesn't work.
// https://github.com/twbs/bootstrap/issues/4550
// $('.dropdown-menu').on('touchstart.dropdown.data-api', function(e) { e.stopPropagation() })


// jQuery(document).ready( function (){
//     jQuery('.dropdown-toggle')
//         .on('touchstart.dropdown', '.dropdown-menu', function (e) { e.stopPropagation(); })
//         .on('touchstart.dropdown', '.dropdown-submenu', function (e) { e.preventDefault(); })
//     })