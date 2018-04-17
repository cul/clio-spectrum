class BestBets < ActiveRecord::Migration[5.1]

  def change

    create_table :best_bets do |t|

      t.string :title, null: false
      t.string :url, null: false
      t.string :description, null: false

      t.text :keywords, null: true

      t.timestamps null: false
    end

    if ActiveRecord::Base.connection.adapter_name.match /mysql/i
      add_index :best_bets, [:title, :url, :description, :keywords], name: 'fulltext', type: :fulltext
    end

  end

end

