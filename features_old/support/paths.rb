module NavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in webrat_steps.rb
  #
  def path_to(page_name)
    case page_name
    
    when /the homepage/
      '/'
    
    when /the home page/
      root_path

    when /the catalog page/
      catalog_index_path
      
    when /the view page/
      catalog_index_path
    
    when /the advanced search page/
      advanced_path
            
    when /the show page for "(.*)"/i
      catalog_path(:id => $1)
    
    when /the mobile show page for "(.*)"/i
      catalog_path(:id => $1,:format=>'mobile')

    when /the request info page for "(.*)" at "(.*)" library/i
      catalog_path(:id => $1,:format=>'request',:lib=>$2)
      
    when /the contact info page/i
      catalog_index_path(:format=>'contact')
      
    when /the mobile search page for "(.*)"/i
      catalog_index_path(:format=>'mobile',:q=>$1)
      
    # Add more page name => path mappings here
    # Here is a more fancy example:
    #
    #   when /^(.*)'s profile page$/i
    #     user_profile_path(User.find_by_login($1))

    else
      raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
#        "Now, go and add a mapping in features/support/paths.rb"
        "Now, go and add a mapping in #{__FILE__}"
    end
  end
end

# Cucumber 0.3
World(NavigationHelpers)

# Cucumber 0.2
=begin
World do |world|
  world.extend NavigationHelpers
  world
end
=end
