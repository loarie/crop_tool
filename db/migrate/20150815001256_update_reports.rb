class UpdateReports < ActiveRecord::Migration
  def change
    change_column :reports, :prec, :float
    change_column :reports, :temp, :float
    change_column :reports, :lat, :float
    change_column :reports, :lon, :float
  end
end
