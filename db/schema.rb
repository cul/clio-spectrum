# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180101010101) do

  create_table "bookmarks", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "document_id"
    t.string "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "user_type"
    t.string "document_type"
    t.index ["user_id"], name: "index_bookmarks_on_user_id"
  end

  create_table "item_alerts", force: :cascade do |t|
    t.string "source", limit: 20, null: false
    t.string "item_key", limit: 32, null: false
    t.string "alert_type", null: false
    t.integer "author_id"
    t.datetime "start_date"
    t.datetime "end_date"
    t.text "message"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["source", "item_key"], name: "index_item_alerts_on_source_and_item_key"
    t.index ["start_date", "end_date"], name: "index_item_alerts_on_start_date_and_end_date"
  end

  create_table "libraries", force: :cascade do |t|
    t.string "hours_db_code", null: false
    t.string "name"
    t.text "comment"
    t.text "url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["hours_db_code"], name: "index_libraries_on_hours_db_code"
  end

  create_table "library_hours", force: :cascade do |t|
    t.integer "library_id", null: false
    t.date "date", null: false
    t.datetime "opens"
    t.datetime "closes"
    t.text "note"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "library_code"
    t.index ["library_code"], name: "index_library_hours_on_library_code"
    t.index ["library_id", "date"], name: "index_library_hours_on_library_id_and_date"
  end

  create_table "locations", force: :cascade do |t|
    t.string "name"
    t.text "found_in"
    t.integer "library_id"
    t.string "category", limit: 12
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "location_code"
    t.string "library_code"
    t.index ["library_code"], name: "index_locations_on_library_code"
    t.index ["library_id"], name: "index_locations_on_library_id"
    t.index ["name"], name: "index_locations_on_name"
  end

  create_table "options", force: :cascade do |t|
    t.integer "entity_id"
    t.string "entity_type", limit: 30
    t.string "association_type", limit: 30
    t.string "name", null: false
    t.text "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["entity_type", "entity_id", "association_type", "name"], name: "entity_association_name"
  end

  create_table "preferences", force: :cascade do |t|
    t.string "login", null: false
    t.text "settings", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["login"], name: "index_preferences_on_login", unique: true
  end

  create_table "saved_list_items", force: :cascade do |t|
    t.integer "saved_list_id"
    t.string "item_source"
    t.string "item_key", limit: 200
    t.integer "sort_order"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["saved_list_id", "item_key"], name: "index_saved_list_items_on_saved_list_id_and_item_key", unique: true
  end

  create_table "saved_lists", force: :cascade do |t|
    t.string "owner", limit: 20, null: false
    t.string "name", limit: 200, null: false
    t.string "slug", limit: 200, null: false
    t.string "description", default: ""
    t.string "sort_by"
    t.string "permissions", default: "private"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["owner", "name"], name: "savedlist_name", unique: true
    t.index ["owner", "slug"], name: "savedlist_url", unique: true
  end

  create_table "searches", force: :cascade do |t|
    t.text "query_params"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "user_type"
    t.index ["user_id"], name: "index_searches_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["session_id"], name: "index_sessions_on_session_id"
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name", limit: 40
    t.string "last_name", limit: 40
    t.string "login", limit: 10
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "password_salt"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["login"], name: "index_users_on_login"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

end
