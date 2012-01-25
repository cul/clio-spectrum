jQuery(document).ready(function($) {
  // Facets already on the page? Turn em into a chart. 
  $(".range_limit .profile .distribution.chart_js ul").each(function() {
      turnIntoPlot($(this).parent());        
  });
    
    
  // Add AJAX fetched range facets if needed, and add a chart to em
  $(".range_limit .profile .distribution a.load_distribution").each(function() {
      var container = $(this).parent('div.distribution');
  
      $(container).load($(this).attr('href'), function(response, status) {
          if ($(container).hasClass("chart_js") && status == "success" ) {
            turnIntoPlot(container);
          }
      });     
  });

  function turnIntoPlot(container) {
    wrapPrepareForFlot($(container), 
      $(container).closest(".range_limit.limit_content"),
      1/(1.618 * 2), // half a golden rectangle, why not. 
      function(container) {
        areaChart($(container));
      });
  }
   
     // Takes a div holding a ul of distribution segments produced by 
    // blacklight_range_limit/_range_facets and makes it into
    // a flot area chart. 
    function areaChart(container) {      
      //flot loaded? And canvas element supported.       
      if (  domDependenciesMet()  ) {
               
        // Grab the data from the ul div
        var series_data = new Array();
        var pointer_lookup = new Array();
        var x_ticks = new Array();
        var min = parseInt($(container).find("ul li:first-child span.from").text());
        var max = parseInt($(container).find("ul li:last-child span.to").text());
        
        $(container).find("ul li").each(function() {
            var from = parseInt($(this).find("span.from").text());
            var to = parseInt($(this).find("span.to").text());
            var count = parseInt($(this).find("span.count").text());
            var avg = (count / (to - from + 1));
            
            
            //We use the avg as the y-coord, to make the area of each
            //segment proportional to how many documents it holds. 
            series_data.push( [from, avg ] );
            series_data.push( [to+1, avg] );
            
            x_ticks.push(from);
            
            pointer_lookup.push({'from': from, 'to': to, 'count': count, 'label': $(this).find(".facet_select").text() });
        });
        var max_plus_one = parseInt($(container).find("ul li:last-child span.to").text())+1; 
        x_ticks.push( max_plus_one );
        


        var plot;
        var config = $(container).closest('.facet_limit').data('plot-config') || {};

        try {
          plot = $.plot($(container), [series_data],
              $.extend(true, config, { 
              yaxis: {  ticks: [], min: 0, autoscaleMargin: 0.1},
            //xaxis: { ticks: x_ticks },
            xaxis: { tickDecimals: 0 }, // force integer ticks
            series: { lines: { fill: true, steps: true }},
            grid: {clickable: true, hoverable: true, autoHighlight: false},
            selection: {mode: "x"}
          }));
        }
        catch(err) {
          alert(err); 
        }
        
        // Div initially hidden to show hover mouseover legend for
        // each segment. 
        $('<div class="subsection hover_legend ui-corner-all"></div>').css('display', 'none').insertAfter(container);
        
        find_segment_for = function_for_find_segment(pointer_lookup);
        $(container).bind("plothover", function (event, pos, item) {
            segment = find_segment_for(pos.x);
            showHoverLegend(container, '<span class="label">' + segment.label + '</span> <span class="count">(' + segment.count + ')</span>');            
        });
        $(container).bind("mouseout", function() {
          $(container).next(".hover_legend").hide();
        });
        $(container).bind("plotclick", function (event, pos, item) {
            if ( plot.getSelection() == null) {
              segment = find_segment_for(pos.x);
              plot.setSelection( normalized_selection(segment.from, segment.to));
            }
        });
        $(container).bind("plotselected plotselecting", function(event, ranges) {
            if (ranges != null ) {
              var from = Math.floor(ranges.xaxis.from); 
              var to = Math.floor(ranges.xaxis.to);
              
              var form = $(container).closest(".limit_content").find("form.range_limit");
              form.find("input.range_begin").val(from);
              form.find("input.range_end").val(to);
              
              var slider_container = $(container).closest(".limit_content").find(".profile .range");           
              slider_container.slider("values", 0, from);
              slider_container.slider("values", 1, to+1);
            }
        });
        
        var form = $(container).closest(".limit_content").find("form.range_limit");        
        form.find("input.range_begin, input.range_end").change(function () {
           plot.setSelection( form_selection(form, min, max) , true );
        });        
        $(container).closest(".limit_content").find(".profile .range").bind("slide", function(event, ui) {
           plot.setSelection( normalized_selection(ui.values[0], Math.max(ui.values[0], ui.values[1]-1)), true);
        });
       
        // initially entirely selected, to match slider
        plot.setSelection( {xaxis: { from:min, to:max+0.9999}}  );
        
        // try to make slider width/orientation match chart's
        var slider_container = $(container).closest(".limit_content").find(".profile .range");
        slider_container.width(plot.width());
        slider_container.css('margin-right', 'auto');
        slider_container.css('margin-left', 'auto');   
        // And set slider min/max to match charts, for sure
        slider_container.slider("option", "min", min);
        slider_container.slider("option", "max", max+1);        
      }
    }
    
    
    // Send endpoint to endpoint+0.99999 to have display
    // more closely approximate limiting behavior esp
    // at small resolutions. (Since we search on whole numbers,
    // inclusive, but flot chart is decimal.)
    function normalized_selection(min, max) {
      max += 0.99999;
      
      return {xaxis: { 'from':min, 'to':max}}
    }
    
    function form_selection(form, min, max) {
      var begin_val = parseInt($(form).find("input.range_begin").val());
      if (isNaN(begin_val) || begin_val < min) {
        begin_val = min;
      }        
      var end_val = parseInt($(form).find("input.range_end").val());
      if (isNaN(end_val) || end_val > max) {
        end_val = max;
      }
      
      return normalized_selection(begin_val, end_val);
    }
    
    function function_for_find_segment(pointer_lookup_arr) {
      return function(x_coord) {
        for (var i = pointer_lookup_arr.length-1 ; i >= 0 ; i--) {
          var hash = pointer_lookup_arr[i];
          if (x_coord >= hash.from)
            return hash;
        }
        return pointer_lookup_arr[0];
      };
    }
        
    function showHoverLegend(container, contents) {
      var el = $(container).next(".hover_legend");

      el.html(contents);                   
      el.show();
    }
    
    // Check if Flot is loaded, and if browser has support for
    // canvas object, either natively or via IE excanvas. 
    function domDependenciesMet() {    
      var flotLoaded = (typeof $.plot != "undefined");
      var canvasAvailable = ((typeof(document.createElement('canvas').getContext) != "undefined") || (typeof  window.CanvasRenderingContext2D != 'undefined' || typeof G_vmlCanvasManager != 'undefined'));

      return (flotLoaded && canvasAvailable);
    }

   /* Set up dom for flot rendering: flot needs to render in a non-hidden
     div with explicitly set width and height. The non-hidden thing
     is annoying to us, since it might be in a hidden facet limit. 
     Can we get away with moving it off-screen? Not JUST the flot
     container, or it will render weird. But the whole parent
     limit content, testing reveals we can. */    
    function wrapPrepareForFlot(container, parent_section, widthToHeight, call_block) {                
        var parent_originally_hidden = $(parent_section).css("display") == "none";
        if (parent_originally_hidden) {
          $(parent_section).show();       
        }
        $(container).width( $(parent_section).width() );
        $(container).height( $(parent_section).width() * widthToHeight );
        if (parent_originally_hidden) {
          parent_section.addClass("ui-helper-hidden-accessible");
        }
        
        call_block(container);
        
        if (parent_originally_hidden) {
          $(parent_section).removeClass("ui-helper-hidden-accessible");
          $(parent_section).hide();
        }
    }
});
