class CreateClimates < ActiveRecord::Migration
  def change
    create_table :climates do |t|
      t.float :lat
      t.float :lon
      t.integer :temp
      t.integer :prec

      t.timestamps null: false
    end
  end
end
