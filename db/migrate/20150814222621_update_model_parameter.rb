class UpdateModelParameter < ActiveRecord::Migration
  def change
    rename_column :model_parameters, :estimates, :estimated_params
  end
end
