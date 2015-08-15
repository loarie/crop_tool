class AddDestinationToReports < ActiveRecord::Migration
  def change
    add_column :reports, :destination, :string
  end
end
