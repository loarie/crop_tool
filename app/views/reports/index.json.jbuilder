json.array!(@reports) do |report|
  json.extract! report, :id, :value, :crop, :statistic
  json.url report_url(report, format: :json)
end
