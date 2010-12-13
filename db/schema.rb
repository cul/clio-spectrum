# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20101213160031) do

  create_table "bookmarks", :force => true do |t|
    t.integer  "user_id",     :null => false
    t.text     "url"
    t.string   "document_id"
    t.string   "title"
    t.text     "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "libraries", :force => true do |t|
    t.string   "hours_db_code", :null => false
    t.string   "name"
    t.text     "comment"
    t.text     "url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "libraries", ["hours_db_code"], :name => "index_libraries_on_hours_db_code"

  create_table "locations", :force => true do |t|
    t.string   "name"
    t.text     "found_in"
    t.integer  "library_id"
    t.string   "category",   :limit => 10
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "locations", ["library_id"], :name => "index_locations_on_library_id"
  add_index "locations", ["name"], :name => "index_locations_on_name"

  create_table "options", :force => true do |t|
    t.integer  "entity_id"
    t.string   "entity_type",      :limit => 30
    t.string   "association_type", :limit => 30
    t.string   "name",                           :null => false
    t.text     "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "options", ["entity_type", "entity_id", "association_type", "name"], :name => "entity_association_name"

  create_table "searches", :force => true do |t|
    t.text     "query_params"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "searches", ["user_id"], :name => "index_searches_on_user_id"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type"], :name => "index_taggings_on_taggable_id_and_taggable_type"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  create_table "users", :force => true do |t|
    t.string   "login",             :null => false
    t.string   "email"
    t.string   "crypted_password"
    t.text     "last_search_url"
    t.datetime "last_login_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "password_salt"
    t.string   "persistence_token"
    t.datetime "current_login_at"
  end

end
