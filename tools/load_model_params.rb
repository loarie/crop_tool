require "csv"
file = File.join(Rails.root, 'tools', 'model_parameters_all.csv')
File.open(file) do |f|
  CSV.foreach(f, col_sep:",", headers: true) do |csv_row|
    ModelParameter.create(country: "Senegal", crop: csv_row[0], statistic: "Yield", estimated_params: "{\"beta\": [#{csv_row[1]},#{csv_row[2]},#{csv_row[3]},#{csv_row[4]},#{csv_row[5]},#{csv_row[6]}], \"sigma2\": #{csv_row[7]}}", priors: "{\"b0\": [#{csv_row[1]},#{csv_row[2]},#{csv_row[3]},#{csv_row[4]},#{csv_row[5]},#{csv_row[6]}], \"Vbcoef\": 1000, \"s1\": 2, \"s2\": #{csv_row[7]}}")
  end
end
