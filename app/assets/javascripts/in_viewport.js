
// http://stackoverflow.com/questions/123999
// how-to-tell-if-a-dom-element-is-visible-in-the-current-viewport

function isElementInViewport (el) {

    //special bonus for those using jQuery
    if (typeof jQuery === "function" && el instanceof jQuery) {
        el = el[0];
    }

    var rect = el.getBoundingClientRect();

    return (
        rect.top >= 0 &&
        rect.left >= 0 &&
        rect.bottom <= (window.innerHeight || document.documentElement.clientHeight) && /*or $(window).height() */
        rect.right <= (window.innerWidth || document.documentElement.clientWidth) /*or $(window).width() */
    );
}


// To replace this:
// %body{onload: "$('.search_q').focus();"}

function focusIfInViewport (el) {
  if (isElementInViewport(el)) {
    el.focus();
  }
}