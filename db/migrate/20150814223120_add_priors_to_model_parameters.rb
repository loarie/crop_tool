class AddPriorsToModelParameters < ActiveRecord::Migration
  def change
    add_column :model_parameters, :priors, :string
  end
end
