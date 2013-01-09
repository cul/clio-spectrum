jQuery(function($) {

  /*****************
   * GENERAL UI    *
   *****************/

  /* tabs */
  $('.tabs').tab()

  /* tooltips */
  $('a[data-rel=tooltip]').tooltip({'placement':'bottom'});
  $('.navbar a[data-rel=tooltip], .navbar label[data-rel=tooltip]').tooltip({'placement': 'bottom'});

  $('.donothing').click(function (e) {
		alert('this does nothing... yet.');
		return false;
  });
  $('.nofollow').click(function (e) {
		alert('disallowing external (non-cu) clicks for now while testing.');
		return false;
  });
  $('div.alert-message a.close').live('click', function (e) {
	$(this).parent('.alert-message').hide();
	return false;
  });
  $('.alert-link').click(function (e) {
	window.location = $(this).find('a').attr('href');
	//return false;
  });

  /* #q keydown */
if ($(window).width() > 767 || $(window).height() > 767) {
  $('#q').bind('keydown', function(){
	$('#advo_link, #clio_source_button').parent().addClass('open');
  });
  $('#q_home').bind('keydown', function(){
	$('#home_advo_link, #clio_source_button').parent().addClass('open');
  });
}

  /* #q focus and blur */
  $('#q').bind('focus', function(){
    $('#top_q_wrapper').addClass('focused');
  });
  $('#q').bind('blur', function(){
    $('#top_q_wrapper').removeClass('focused');
  });
  $('#q_home').bind('focus', function(){
    $('#home_q_wrapper').addClass('focused');
  });
  $('#q_home').bind('blur', function(){
    $('#home_q_wrapper').removeClass('focused');
  });

  /* keep sources dropdown open even after radio click */
  $('#top_q_wrapper .dropdown-menu input, #top_q_wrapper .dropdown-menu label, #home_q_wrapper .dropdown-menu input, #home_q_wrapper .dropdown-menu label').click(function(e) {
    e.stopPropagation();
  });

  /* autostart carousels */
  LDPD.startCarousels();

  /* scroll to top function */
  function scrollToTop() {
    $('body,html').animate({ scrollTop: 0 }, 800);
  }

  /***** search datasource switcher (sources dropdown) *****/
  var hcurrentradio= $("#clio_home_search input[name='datasource']:checked")[0];
	if ( $("#clio_home_search input[name='datasource']:checked").next('span').attr('data-placeholder') ) {
		var hnewplaceholder = $("#clio_home_search input[name='datasource']:checked").next('span').attr('data-placeholder');
	}
        $('#home_advo_link span, #clio_source_button span').text($("#clio_home_search input[name='datasource']:checked").next('span').attr('data-shortlabel')); //for firefox
	if (hnewplaceholder) { $('#q_home').attr('placeholder', hnewplaceholder); }
	if ($(hcurrentradio).attr('data-fieldfilter')) {
		$('#clio_field_button').css('visibility','visible');
		if ($(hcurrentradio).attr('data-fieldfilter')=='2') {
			$('#clio_searchfield option[data-ver=2]').hide();
		} else {
			$('#clio_searchfield option[data-ver=2]').show();
		}
		$('#clio_searchfield option:eq(0)').attr('selected','selected');
	} else {
		$('#clio_field_button').css('visibility','hidden'); // fieldfilter visibility for firefox
	}
  // do the change
  $('#clio_home_search input[name=datasource]').change(function() {
    var hnewradio= $("#clio_home_search input[name='datasource']:checked")[0];
	if ( $("#clio_home_search input[name='datasource']:checked").next('span').attr('data-placeholder') ) {
		var hnewplaceholder = $("#clio_home_search input[name='datasource']:checked").next('span').attr('data-placeholder');
	}
    if (hnewradio===hcurrentradio) {
        return;
    } else {
        $('#home_advo_link span, #clio_source_button span').text($("#clio_home_search input[name='datasource']:checked").next('span').attr('data-shortlabel'));
        hcurrentradio= hnewradio;
        hcurrentradio.checked= true;
		if (hnewplaceholder) { $('#q_home').attr('placeholder', hnewplaceholder); }
		// fieldfilter visibility
		if ($(hcurrentradio).attr('data-fieldfilter')) {
			$('#clio_field_button').css('visibility','visible');
				$('#clio_field_button').css('visibility','visible');
				if ($(hcurrentradio).attr('data-fieldfilter')=='2') {
					$('#clio_searchfield option[data-ver=2]').hide();
				} else {
					$('#clio_searchfield option[data-ver=2]').show();
				}
				$('#clio_searchfield option:eq(0)').attr('selected','selected');
		} else {
			$('#clio_field_button').css('visibility','hidden');
		}
    }
  });
  var currentradio= $("input[name='datasource']:checked")[0];
        $('#advo_link span').text($("input[name='datasource']:checked").next('span').attr('data-shortlabel')); //for firefox
  $('input[name=datasource]').change(function() {
    var newradio= $("input[name='datasource']:checked")[0];
    if (newradio===currentradio) {
        return;
    } else {
        $('#advo_link span').text($("input[name='datasource']:checked").next('span').attr('data-shortlabel'));
        currentradio= newradio;
        currentradio.checked= true;
    }
  });

  /***** search clio field switcher (secondaryj dropdown) *****/
/*
  var fcurrentradio= $("#clio_home_search input[name='search_field']:checked")[0];
    if ( $("#clio_home_search input[name='search_field']:checked").next('span').attr('data-placeholder') ) {
        var fnewplaceholder = $("#clio_home_search input[name='search_field']:checked").next('span').attr('data-placeholder');
    }
        $('#clio_field_button span').text($("#clio_home_search input[name='search_field']:checked").next('span').text()); //for firefox
  $('#clio_home_search input[name=search_field]').change(function() {
    var fnewradio= $("#clio_home_search input[name='search_field']:checked")[0];
    if ( $("#clio_home_search input[name='search_field']:checked").next('span').attr('data-placeholder') ) {
        var fnewplaceholder = $("#clio_home_search input[name='search_field']:checked").next('span').attr('data-placeholder');
    }
    if (fnewradio===fcurrentradio) {
        return;
    } else {
        $('#clio_field_button span').text($("#clio_home_search input[name='search_field']:checked").next('span').text());
        fcurrentradio= fnewradio;
        fcurrentradio.checked= true;
    }
  });
  var tfcurrentradio= $("input[name='search_field']:checked")[0];
  $('input[name=search_field]').change(function() {
    var tfnewradio= $("input[name='search_field']:checked")[0];
    if (tfnewradio===tfcurrentradio) {
        return;
    } else {
        tfcurrentradio= tfnewradio;
        tfcurrentradio.checked= true;
    }
  });
*/

  /*** clio_home_search build and submit search query ***/
  $('#clio_home_search .submitss').click(function(e) {
	var formaction = 'http://cliobeta.columbia.edu/'+$("#clio_home_search input[name='datasource']:checked").attr('value');
	$('#clio_home_search').attr('action', formaction); //.submit();
	$('#clio_home_search').submit();
  });
  $('#q_home').keypress(function(e){
        if(e.which == 13){//Enter key pressed
            $('#clio_home_search .submitss').click();//Trigger search button click event
		}
  });
  // for stupid tabbed form option
  $('#tabforms .submitss').click(function(e) {
	$(this).closest('form').submit();
  });
});

//Define LDPD namespace to avoid function name collisions
var LDPD = {};

/*
 * Using separate startCarousel function so that it
 * can be called safely even after document ready.
 * Also implements fix for currently-not-working
 * data-interval attribute.
 */
LDPD.startCarousels = function() {
 $('.carousel').each(function(){

   //Only start carousels that aren't already running
   if($(this).attr('data-is-running') == undefined) {

	 //Apply fix for non-working data-interval, but default to 6000 for interval speed otherwise
	 $(this).carousel({
	   interval: ($(this).attr('data-interval') != undefined) ? parseInt($(this).attr('data-interval')) : 6000
	 });
	 $(this).attr('data-is-running', 'true');

   }

 });
};
