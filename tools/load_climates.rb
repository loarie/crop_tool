require "csv"
file = File.join(Rails.root, 'tools', 'climate_data.csv')
File.open(file) do |f|
  CSV.foreach(f, col_sep:",", headers: true) do |csv_row|
    Climate.create(lat: csv_row[0], lon: csv_row[1], temp: csv_row[2], prec: csv_row[3])
  end
end