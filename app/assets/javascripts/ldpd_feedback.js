$(document).ready(function() {


    $('.feedback-popup').bind('click', function(){
        if(!LWEB.feedbackDialogIsSetup) {
          LWEB.setupFeedbackDialog();
          LWEB.feedbackDialogIsSetup = true;
        }
        LWEB.showFeedbackDialog();
    });

    $(window).resize(function(){
        if(LWEB.feedbackDialogIsVisible) {
            LWEB.centerFeedbackDialog();
        }
    });

    $(window).scroll(function(){
        if(LWEB.feedbackDialogIsVisible) {
            LWEB.centerFeedbackDialog();
        }
    });

}); //ready

var LWEB = {};

LWEB.feedbackDialogIsSetup = false;
LWEB.feedbackDialogIsVisible = false;

LWEB.setupFeedbackDialog = function() {
    $('<div id="feedback_dialog"><span id="dragme"></span><a id="close_feedback_dialog" href="#" onclick="LWEB.hideFeedbackDialog();"><span class="glyphicon glyphicon-remove"></span></a><span id="dragme"></span><iframe width="600" height="400" src="https://feedback.cul.columbia.edu/feedback_submission/clio?submitted_from_page=' + window.location.href + '"></iframe></div>').hide().appendTo('body');
    $('#feedback_dialog').css(
        {
        'z-index':'10000',
        'position':'absolute',
        'border': '3px solid rgb(187, 187, 187)' 
        
        }
    );

    $('#feedback_dialog iframe').css(
        {
        'border':'none'
        }
    );

    $('.glyphicon-remove').css(
        {
        'position':'relative',
        'right':'4px',
        'top':'-6px',
        }
    );

    $('#dragme').css(
    {
		    'position':'absolute',
		    'top':'0px',
		    'left':'0px',
		    'height':'60px',
		    'width':'100%',
		    // DEBUG
		    // 'background':'red',
		    // 'opacity':'0.1'
		    }
	  );

    $('#feedback_dialog #close_feedback_dialog').css(
        {
        'position':'absolute',
        'right' : '20px',
        'top' : '8px',
        'display' : 'inline-block',
        'width' : '1px',
        'height' : '1px',
        'text-align' : 'center',
        'border' : 'none',
        'padding' : '5px',
        'background-color' : '#EEEEFF'
        }
    );

    LWEB.centerFeedbackDialog();
};

LWEB.showFeedbackDialog = function() {

    LWEB.centerFeedbackDialog();
    $('#feedback_dialog').show();
    $('#feedback_dialog').draggable();
    LWEB.feedbackDialogIsVisible = true;

    return false;
};

LWEB.hideFeedbackDialog = function() {
    $('#feedback_dialog').hide();
    LWEB.feedbackDialogIsVisible = false;
    // NEXT-936 - Keep the CLIO feedback button open while using CLIO
    // We've now been asked to save state when the form is closed/reopened.
    // // NEXT-668 - Can't submit more than one feedback on the same page
    // // reload the feedback form, away from thank-you, to empty form again,
    // // by setting it's src to itself, to force reload - in one line. 
    // //   http://stackoverflow.com/questions/4249809
    // $( '#feedback_dialog iframe' ).attr( 'src', function ( i, val ) { return val; });

    return false;
};

LWEB.centerFeedbackDialog = function() {

    var feedbackDialogElement = $('#feedback_dialog');

    var newX = $(window).width()/2 - feedbackDialogElement.width()/2;
    var newY = $(window).height()/2 - feedbackDialogElement.height()/2 + $(window).scrollTop();
    var maxHeight = $(window).height()*.75;
    maxHeight = (maxHeight > 525) ? 525 : maxHeight;
    var maxWidth = $(window).width()*.5;
    maxWidth = (maxWidth > 800) ? 600 : maxWidth;

    $('#feedback_dialog').css(
        {
        'left': newX + 'px',
        'top' : newY + 'px',
        }
    );

     $('#feedback_dialog, #feedback_dialog iframe').css(
        {
        'width' : '100%',
        'height' : '100%',
        'max-width' : maxWidth + 'px',
        'max-height' : maxHeight + 'px'
        }
     );
   };
