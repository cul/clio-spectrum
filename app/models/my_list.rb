class MyList < ActiveRecord::Base
  attr_accessible :owner, :name, :slug, :description, :sort_by, :permissions
  has_many :my_list_items, :dependent => :destroy
  has_paper_trail

  SERVICE_URL_PREFIX = "/mylist"
  DEFAULT_LIST_NAME = "default"

  # stringex
  acts_as_url :name, :url_attribute => :slug, :scope => :owner, :sync_url => true

  def is_default?
    return name == DEFAULT_LIST_NAME
  end

  def url
    url = "#{SERVICE_URL_PREFIX}/#{owner}"
    url += "/#{slug}" unless is_default?
    url
  end

  def size
    my_list_items.size
  end

  def display_name
    return "My List" if is_default?
    return name
  end


end
