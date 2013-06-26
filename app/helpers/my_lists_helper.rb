module MyListsHelper


def get_list_url(list)
  url = mylist_path(:only_path => false) + "/" + current_user.login
  url += "/#{list.slug}" unless list.is_default?
  url
end

def get_list_name(list)
  return "My List" if list.is_default?
  return list.name
end


end
