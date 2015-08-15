class UpdateReports < ActiveRecord::Migration
  def change
    change_column :reports, :prec, 'float USING CAST(prec AS float)'
    change_column :reports, :temp, 'float USING CAST(temp AS float)'
    change_column :reports, :lat, 'float USING CAST(lat AS float)'
    change_column :reports, :lon, 'float USING CAST(lon AS float)'
  end
end
