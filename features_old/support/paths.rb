module NavigationHelpers
  def path_to(page_name)
    case page_name
    

    when /the home page/
      root_path   
    # Add more page name => path mappings here
    else
      if path = match_rails_path_for(page_name) 
        path
      else 
        raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
        "Now, go and add a mapping in features/support/paths.rb"
      end
    end
  end

  def match_rails_path_for(page_name)
    if page_name.match(/the (.*) page/)
      return send "#{$1.gsub(" ", "_")}_path" rescue nil
    end
  end
end

World(NavigationHelpers)
