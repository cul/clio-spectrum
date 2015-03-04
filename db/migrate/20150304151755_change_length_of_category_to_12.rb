class ChangeLengthOfCategoryTo12 < ActiveRecord::Migration
  def up
    change_column :locations, :category, :string, :limit => 12
  end

  def down
    change_column :locations, :category, :string, :limit => 10
  end
end
