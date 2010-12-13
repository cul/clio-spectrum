class HoursDb::HoursLibrary < ActiveRecord::Base
  establish_connection "hours_db_prod"
  set_table_name "Libraries"


  def export_to_new_books
    library = Library.find_by_hours_db_code(lib_code)

    unless library
      library = Library.create(
        :hours_db_code => lib_code, 
        :name => lib_name, 
        :comment => (lib_comment.to_s + " " + lib_comment_below.to_s).strip, 
        :url => lib_url
      )
    end

    library
  end


  def self.export_all
    self.find(:all).each { |hl| hl.export_to_new_books }
  end
end
