
# UNUSED with move to AJAX-based lookups against LibraryWeb mapping API

# module LocationsHelper
#   MAP_IMAGE_SIZES = {
#     'http://www.columbia.edu/cu/lweb/data/services/maps/images/sectionC.gif' => [304, 500],
#     'http://www.columbia.edu/cu/lweb/data/services/maps/images/sectionA.gif' => [560, 346],
#     'http://www.columbia.edu/cu/lweb/data/services/maps/images/sectionB.gif' => [550, 302],
#     'http://www.columbia.edu/cu/lweb/data/services/maps/images/sectionD.gif' => [530, 318],
#     'http://www.columbia.edu/cu/lweb/data/services/maps/images/sectionF.gif' => [250, 500],
#     'http://www.columbia.edu/cu/lweb/data/services/maps/images/sectionG.gif' => [530, 335],
#     'http://www.columbia.edu/cu/lweb/data/services/maps/images/sectionE.gif' => [530, 318]
# 
#   }
# 
#   def map_image_tag(map_url, max_height, max_width)
#     return '' unless  map_url
#     if (orig_size = MAP_IMAGE_SIZES[map_url])
#       width, height = orig_size
#       if width > max_width
#         height = height / (width / max_width.to_f)
#         width = max_width
#       elsif height > max_height
#         width = width / (height / max_height.to_f)
#         height = max_height
#       end
# 
#       size = height.to_s + 'X' + width.to_s
#       content_tag('div', image_tag(map_url, height: height, width: width), class: 'map')
#     else
#       content_tag('div', image_tag(map_url), class: 'map')
# 
#     end
#   end
# end
