class SavedList < ActiveRecord::Base
  attr_accessible :owner, :name, :slug, :description, :sort_by, :permissions
  has_many :saved_list_items, dependent: :destroy
  has_paper_trail

  SERVICE_URL_PREFIX = '/lists'
  DEFAULT_LIST_NAME = 'Bookbag'
  DEFAULT_LIST_SLUG = 'bookbag'

  # stringex
  acts_as_url :name, url_attribute: :slug, scope: :owner, sync_url: true

  def is_default?
    name == DEFAULT_LIST_NAME
  end

  def url
    url = "#{SERVICE_URL_PREFIX}/#{owner}/#{slug}"
    url
  end

  def size
    saved_list_items.size
  end

  def display_name
    return DEFAULT_LIST_NAME if is_default?
    name
  end
end
