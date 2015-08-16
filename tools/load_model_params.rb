require "csv"
file = File.join(Rails.root, 'tools', 'model_parameters_all_log.csv')
File.open(file) do |f|
  CSV.foreach(f, col_sep:",", headers: true) do |csv_row|
    vbcoef = 500000
    sigma2 = csv_row[7]
    s1 = 10 + 1
    s2 = 10 * sigma2
    ModelParameter.create(country: nil, crop: csv_row[0], statistic: "Yield", estimated_params: "{\"beta\": [#{csv_row[1]},#{csv_row[2]},#{csv_row[3]},#{csv_row[4]},#{csv_row[5]},#{csv_row[6]}], \"sigma2\": #{csv_row[7]}}", priors: "{\"b0\": [#{csv_row[1]},#{csv_row[2]},#{csv_row[3]},#{csv_row[4]},#{csv_row[5]},#{csv_row[6]}], \"Vbcoef\": #{vbcoef}, \"s1\": #{s1}, \"s2\": #{s2}}")
  end
end
