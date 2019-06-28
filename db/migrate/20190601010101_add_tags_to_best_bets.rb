class AddTagsToBestBets < ActiveRecord::Migration[5.1]

  def up
    add_column :best_bets, :tags, :text
    # When migration runs, all records are CLIO Best Bets
    BestBet.update_all(tags: 'BestBets')
  end
  
  def down
    remove_column :best_bets, :tags
  end

end
