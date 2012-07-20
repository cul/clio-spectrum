class DatabaseAlert < ActiveRecord::Base
  attr_accessible :active, :author_id, :clio_id, :message
end
