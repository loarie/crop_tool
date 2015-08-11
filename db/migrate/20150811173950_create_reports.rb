class CreateReports < ActiveRecord::Migration
  def change
    create_table :reports do |t|
      t.float :value
      t.string :crop
      t.string :statistic

      t.timestamps null: false
    end
  end
end
