class AddColumnsToReports < ActiveRecord::Migration
  def change
    add_column :reports, :country, :string
    add_column :reports, :city, :string
    add_column :reports, :lat, :string
    add_column :reports, :lon, :string
    add_column :reports, :temp, :string
    add_column :reports, :prec, :string
    add_column :reports, :identity, :string
  end
end
