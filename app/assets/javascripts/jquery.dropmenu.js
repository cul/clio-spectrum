/*!
 * jQuery PLUGIN - for jQuery 1.3+
 * http://www.sitebase.be
 *
 * Copyright 2011, Wim Mostmans (http://www.sitebase.be)
 * You need to buy a license if you want use this script.
 * http://codecanyon.net/wiki/support/legal-terms/licensing-terms/
 *
 * @package Drop Menu
 * @author Sitebase (http://www.sitebase.be)
 * @version 1.1.1
 * @license http://codecanyon.net/wiki/support/legal-terms/licensing-terms/
 * @copyright Copyright (c) 2008-2011 Sitebase (http://www.sitebase.be) 
 * @date: 29-06-2011
 */
(function($){
	$.fn.dropmenu = function(custom) {
		
		// Default plugin settings
		var defaults = {
		  	openAnimation: "size",
			closeAnimation: "slide",
			openClick: false,
			openSpeed: 300,
			closeSpeed: 200,
			closeDelay: 200,
			onHide: function(){},
			onHidden: function(){},
			onShow: function(){},
			onShown: function(){},
			zindex: 100,
			openMenuClass: 'open',
			autoAddArrowElements: true
		};
		
		// Merge default and user settings
		var settings = $.extend({}, defaults, custom);
		
		// Declare vars
		var delayTimer = "";
		var menu = $(this);

		// Disable CSS menu opening because Javascript is enabled
		var main_menu_items = menu.find('> li').children('ul, div').css('display', 'none').end().find('ul ul, li > div').css('display', 'none').end();
	
		// Remove CSS hover action
		menu.removeClass('css-only');

		// Add class to all menu items that have children
		var all_menu_items = menu.find('li > ul, li > div').parent().addClass("dropitem");
		
		// Add arrow element to navigation items with children
		if(settings.autoAddArrowElements){
			all_menu_items.find('> a').append('<span class="arrow"></span>');	
		}
		
		// Add hover/leave event handler to all menu items that have children
		$(all_menu_items).hover(function(){
			
			if(settings.closeDelay != 0){
				// Clear close timer
				window.clearInterval(delayTimer);
				
				// Close all the opened menus
				closeAllSiblings($(this));
			}
		
			// Only do hover open when openClick settings is disabled
			if(!settings.openClick && !$(this).is('.' + settings.openMenuClass)){
				// Callback onshow 
				settings.onShow.call($(this));
			
				// Open menu
				openMenu($(this));
			}

		}, function() {
			
			// Callback onHide 
			settings.onHide.call($(this));
			
			if(settings.closeDelay == 0){
				closeMenu($(this).find('li.' + settings.openMenuClass));
				closeMenu($(this));
			}else{
				var menu = $(this);
				window.clearInterval(delayTimer);
				delayTimer = setInterval(function(){
					window.clearInterval(delayTimer);
					closeMenu($(menu).find('li.' + settings.openMenuClass));
					closeMenu(menu);
				}, settings.closeDelay);
			}
		});
		
		// Bind click menu item if openClick setting is enabled
		if(settings.openClick){
			$(all_menu_items).click(function(){
				// Callback onshow 
				settings.onShow.call($(this));
				
				// Open menu
				openMenu($(this));
			});
		}
		
		
		/**
		 * Function that is triggered to open
		 * a specific item submenu
		 *
		 * @param hovered item
		 * @return void
		 */
		function openMenu(menu_item){
			
			// Get menu box
			var menu_box = menu_item.find('> ul, > div').stop(true, true);
			
			// This will make the selected menu always on top of the
			// non selected menu
			$(menu_item).parent()
						.find("ul, div")
						.css("z-index", settings.zindex);
			menu_box.css("z-index", (settings.zindex+1));

			// If animation is function
			if(typeof settings.openAnimation == 'function'){
				$(menu_item).addClass(settings.openMenuClass)
				settings.openAnimation.call(menu_box);
				return;
			}
			
			if(!$(menu_item).is('.' + settings.openMenuClass)){
				  switch(settings.openAnimation){
					  case 'fade':
						  fadeAnimation(menu_box, true);
						  break;
					  case 'size':
						  sizeAnimation(menu_box, true);
						  break;	
					  default:
						  slideAnimation(menu_box, true);
						  break;
				  }
			}
				
		}
		
		/**
		 * Function that is triggered to close
		 * a specific item submenu
		 *
		 * @param hovered item
		 * @return void
		 */
		function closeMenu(menu_item){
			
			// Get menu box
			var menu_box = menu_item.find('> ul, > div').stop(true, true);
			
			// If animation is function
			if(typeof settings.closeAnimation == 'function'){
				$(menu_item).removeClass(settings.openMenuClass)
				settings.closeAnimation.call(menu_box);
				return;
			}
			
			switch(settings.closeAnimation){
				case 'fade':
					fadeAnimation(menu_box, false);
					break;
				case 'size':
					sizeAnimation(menu_box, false);
					break;
				default:
					slideAnimation(menu_box, false);
					break;
			}
		}
		
		/**
		 * Animation where the menu slides
		 *
		 * @param menu item
		 * @param bool
		 * @return void
		 */
		function slideAnimation(menu_item, do_open){
			if(do_open){
				$(menu_item).parent().addClass(settings.openMenuClass).end().slideDown(settings.openSpeed, function(){cbShown($(menu_item))});	
			}else{
				$(menu_item).slideUp(settings.closeSpeed, 
					function(){
						$(this).parent().removeClass(settings.openMenuClass);
						cbHidden($(menu_item));
					}
				);
			}
		}
		
		/**
		 * Animation where the menu fades
		 *
		 * @param menu item
		 * @param bool
		 * @return void
		 */
		function fadeAnimation(menu_item, do_open){
			if(do_open){
				$(menu_item).parent().addClass(settings.openMenuClass).end().fadeIn(settings.openSpeed, function(){cbShown($(menu_item))});	
			}else{
				$(menu_item).fadeOut(settings.closeSpeed, 
					function(){
						$(this).parent().removeClass(settings.openMenuClass);
						cbHidden($(menu_item));
					}
				);
			}
		}
		
		/**
		 * Animation where the menu size fades
		 *
		 * @param menu item
		 * @param bool
		 * @return void
		 */
		function sizeAnimation(menu_item, do_open){
			if(do_open){
				$(menu_item).parent().addClass(settings.openMenuClass).end().show(settings.openSpeed, function(){cbShown($(menu_item))});	
			}else{
				$(menu_item).hide(settings.closeSpeed, 
					function(){
						$(this).parent().removeClass(settings.openMenuClass);
						cbHidden($(menu_item));
					}
				);
			}
		}
		
		/**
		 * Close all the currently opened menus
		 *
		 * @return void
		 */
		function closeAllSiblings(selected){
			var submenus = selected.siblings('.' + settings.openMenuClass);
			$.each(submenus, function(i, val) {
				var opened_menus = $(submenus[i]).find('li.' + settings.openMenuClass);
				opened_menus.css("z-index", (settings.zindex-1));
				closeMenu(opened_menus);
				closeMenu($(submenus[i]));
			});
		}
		
		/**
		 * Function that triggers the shown callback
		 *
		 * @return void
		 */
		function cbShown(menu_item){
			settings.onShown.call($(menu_item).parent())
		}
		
		/**
		 * Function that triggers the shown callback
		 *
		 * @return void
		 */
		function cbHidden(menu_item){
			settings.onHidden.call($(menu_item).parent())
		}

		// returns the jQuery object to allow for chainability.
		return this;
	}
	
})(jQuery);


//http://preview.sitebase.be/detect.php?display_message=true
