class CreateModelParameters < ActiveRecord::Migration
  def change
    create_table :model_parameters do |t|
      t.string :country
      t.string :crop
      t.string :statistic
      t.string :estimates

      t.timestamps null: false
    end
  end
end
