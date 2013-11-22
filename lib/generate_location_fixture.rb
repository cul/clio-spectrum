# UNUSED
# (used once, to initialize, but we're split off from this now)

# require "rubygems"
# require "httpclient"
# require "nokogiri"
# require "yaml"
# require "ruby-debug"
# 
# url = "http://www.columbia.edu/cu/lweb/help/clio/location_guide.html"
# 
# source = Nokogiri::HTML(HTTPClient.new.get_content(url))
# 
# rows = source.css("#divContent div br~table").first.css("tr")
# 
# non_physical_locations = [ "Health Sciences Web", "Dakhla Library", "LibraryWeb", "Offsite"]
# 
# name_location_map = {
#   "African Studies" => "butler",
#   "Ancient/Medieval" => "butler",
#   "Avery" => "avery",
#   "Barnard" => "barnard",
#   "Burke" => "burke",
#   "Business" => "business",
#   "Butler" => "butler",
#   "Butler Media" => "bmc",
#   "Butler Microforms" => "pmrr",
#   "Butler Periodicals" => "pmrr",
#   "Butler Reference" => "butlref",
#   "Butler Reserves" => "butlres",
#   "Butler Stacks" => "butler",
#   "Chemistry Reference" => "chemistryref",
#   "Early Modern/Modern Europe" => "butler",
#   "East Asian" => "east asian",
#   "Electronic Text Service" => "butler",
#   "Engineering" => "eng",
#   "Geology" => "geology",
#   "Geoscience" => "geosci",
#   "Health Sciences" => "hsl",
#   "Islamic Studies" => "butler",
#   "Journalism" => "jour",
#   "Latin American Studies" => "butler",
#   "Lehman" => "lehman",
#   "Lehman Electronic Data Service" => "eds",
#   "Lehman Map Room" => "lehman",
#   "Lehman Suite" => "lehsuite",
#   "Lehman US Government Documents" => "lehman",
#   "Math-Science" => "mathsci",
#   "Mathematics" => "mathsci",
#   "Milstein" => "butler",
#   "Modern & Comparative Studies" => "butler",
#   "Moral & Political Theory" => "butler",
#   "Music" => "music",
#   "Oral History" => "butler",
#   "Papyrus & Epigraphy" => "butler",
#   "Rare Book" => "rbml",
#   "Science" => "Science",
#   "Social Work" => "socwk",
#   "South Asian Studies" => "butler",
#   "US History & Literature" => "butler",
#   "University Archives" => "uarchives"
# }
# 
# results = []
# 
# rows.each do |row|
# 
#   next unless row.css("th").empty?
# 
#   cells = row.css("td")
# 
#   result = {}
#   result[:links] = {}
#   location = cells[0].text.strip
#   result[:location] = location
#   result[:found_in] = cells[1].text.strip
# 
#   process_links = true
# 
#   if name_location_map[location]
#     result[:library_code] = name_location_map[location]
#     result[:category] = "physical"
#   elsif non_physical_locations.include?(location)
#     result[:category] = "no_location"
#   else
#     puts "no location for #{location}"
#     result[:category] = "physical"
#   end
# 
#   result[:links]["Home Page"] = cells[1].at_css("a").attributes["href"].value if cells[1].at_css("a")
#   if cells[2].at_css("a")
#     map = cells[2].at_css("a").attributes["href"].value
#     result[:links]["Map"] = map
#     if map.include?("http://www.columbia.edu/cu/lweb/services/maps/section")
#       result[:links]["Map URL"] = map.gsub("lweb", "lweb/data").gsub("maps","maps/images").gsub(".html",".gif")
#     end
#   end
# 
#   cells[3].css("a").each do |node|
#     result[:links][node.text] = node.attributes["href"].value
#   end
# 
#   results << result
# end
# 
# 
# 
# 
# File.open("config/locations_fixture.yml", "w") { |f| f.write(results.to_yaml) }
# 
# 
