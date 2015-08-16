class TextMessage < ActiveRecord::Base
  require 'open-uri'
  
  after_create :process

  COUNTRY_HASH = {
    senegal: {wb: 'SEN', go: 'sn', pretty: 'Senegal'},
    cabo_verde: {wb: 'CPV', go: 'cp', pretty: 'Cabo Verde'},
    benin: {wb: 'CPV', go: 'cp', pretty: "Benin"},
    gambia: {wb: 'CPV', go: 'cp', pretty: "Gambia"},
    ghana: {wb: 'CPV', go: 'cp', pretty: "Ghana"},
    guinea: {wb: 'CPV', go: 'cp', pretty: "Guinea"},
    ivory_coast: {wb: 'CPV', go: 'cp', pretty: "Côte d'Ivoire"},
    liberia: {wb: 'CPV', go: 'cp', pretty: "Liberia"},
    mali: {wb: 'CPV', go: 'cp', pretty: "Mali"},
    mauritania: {wb: 'CPV', go: 'cp', pretty: "Mauritania"},
    niger: {wb: 'CPV', go: 'cp', pretty: "Niger"},
    nigeria: {wb: 'CPV', go: 'cp', pretty: "Nigeria"},
    guinea_bissau: {wb: 'CPV', go: 'cp', pretty: "Guinea-Bissau"},
    sierra_leopne: {wb: 'CPV', go: 'cp', pretty: "Sierra Leone"},
    togo: {wb: 'CPV', go: 'cp', pretty: "Togo"},
    burkina_faso: {wb: 'CPV', go: 'cp', pretty: "Burkina Faso"}
  }
  CROPS = ["Maize","Millet","Sorghum","Fonio","Cereals, nes","Potatoes","Sweet potatoes","Cassava","Sugar cane","Cow peas, dry","Pulses, nes","Cashew nuts, with shell","Nuts, nes","Groundnuts, with shell","Coconuts","Oil, palm fruit","Sesame seed","Melonseed","Seed cotton","Cabbages and other brassicas","Tomatoes","Pumpkins, squash and gourds","Eggplants (aubergines)","Onions, dry","Beans, green","Carrots and turnips","Okra","Vegetables, fresh nes","Bananas","Oranges","Watermelons","Mangoes, mangosteens, guavas","Fruit, tropical fresh nes","Fruit, fresh nes","Chillies and peppers, dry","Cereals,Total","Roots and Tubers,Total","Pulses,Total","Treenuts,Total","Oilcrops Primary","Vegetables Primary","Fibre Crops Primary","Vegetables&Melons, Total","Fruit excl Melons,Total","Citrus Fruit,Total","Coarse Grain, Total","Cereals (Rice Milled Eqv)","Oilcakes Equivalent"]
  STATISTICS = ["Yield","Planting","Harvest"]
  
  def process
    if to == "+"+phone_number.to_s
      code = body.split(",")
      error ||= true unless code.count >= 3
      error ||= true unless CROPS.include? code[0].capitalize
      error ||= true unless STATISTICS.include? code[1].capitalize
      error ||= true unless (code.count == 3 || (code.count == 4 && code[3].to_f != 0.0))
      
      if error
        new_sentence = "Error, we didn't understand #{body}"
      else
        if code.count == 3 #request
          
          new_sentence = "Our #{code[1]} estimate for #{code[0]} is #{TextMessage.stats(code)}"
          
        else #reporting data
          crop = code[0]
          stat = code[1]
          city = code[2]
          val = code[3].to_f
          
          coords = TextMessage.get_coords(city)
          climate = TextMessage.get_climate(coords[:lat], coords[:lon])
    
          Report.create(country: coords[:country], city: city.capitalize, lat: coords[:lat], lon: coords[:lon], crop: crop.capitalize, statistic: stat.capitalize, value: val, temp: climate[:temp], prec: climate[:prec], identity: from, destination: to)
          new_sentence = "Thank you for submitting your request of #{body}"
          
          update_model(crop, stat)
          
        end
      end
      TextMessage.create(to: from, from: phone_number, body: new_sentence)
    else
      send_outgoing
    end
  end
  
  def send_outgoing
    client.messages.create(
      to: to,
      from: from,
      body: body
    )
  end
  
  def update_model(crop, stat)
    #get_priors
    mp = ModelParameter.where(crop: crop.capitalize, statistic: stat.capitalize).first
    priors = JSON.parse mp.priors
    b0 = priors["b0"].to_s.gsub("[","c(").gsub("]",")")
    
    #get_data
    data = Report.where(crop: crop.capitalize, statistic: stat.capitalize).all
    y = data.map(&:value).to_s.gsub("[","c(").gsub("]",")")
    x1 = data.map(&:temp).to_s.gsub("[","c(").gsub("]",")")
    x2 = data.map(&:prec).to_s.gsub("[","c(").gsub("]",")")
    
    #update the model
    input_params = {'b0' => b0, 'Vbcoef' => priors["Vbcoef"], 's1' => priors["s1"], 's2' => priors["s2"], 'y' => y, 'x1' => x1, 'x2' => x2}
    ocpu_call = Net::HTTP.post_form(URI.parse('http://104.236.132.146/ocpu/library/cropmodel/R/crop_function'), input_params)
    ocpu_dir = ocpu_call.body.split("/")[3]
    ocpu_response = Net::HTTP.get(URI.parse("http://104.236.132.146/ocpu/tmp/#{ocpu_dir}/stdout/text"))
    output_params = ocpu_response.split("\"")[1].gsub("beta","\"beta\"").gsub("sigma2","\"sigma2\"")
    
    #update database
    mp.estimated_params = output_params
    mp.save
  end
  
  def self.get_coords(city)
    google_key = Rails.application.secrets.google_key
    ##url = "https://maps.googleapis.com/maps/api/geocode/json?address=#{city}&region=#{COUNTRY_HASH[:senegal][:go]}&key=#{google_key}"
    url = "https://maps.googleapis.com/maps/api/geocode/json?address=#{city}&key=#{google_key}"
    json_string = open(url).read
    parsed_json = JSON.parse(json_string)
    country = parsed_json["results"][0]["address_components"][3]["long_name"]
    coords = parsed_json["results"][0]["geometry"]["location"]
    return {lat: coords["lat"], lon: coords["lng"], country: country}
    #return {lat: 5.6, lon: -0.19, country: "Ghana"}
  end
  
  def self.get_climate(lat, lon)
    #wunderground_key = Rails.application.secrets.wunderground_key
    #json_string = open("http://api.wunderground.com/api/#{wunderground_key}/geolookup/q/#{lat},#{lon}.json").read
    #parsed_json = JSON.parse(json_string)
    #country = parsed_json["location"]["country_name"]
    #city = parsed_json["location"]["city"].gsub(" ","_")
    
    #url = "http://api.wunderground.com/api/#{wunderground_key}/planner_08010830/q/#{country}/#{city}.json"
    #json_string = open(url).read
    #parsed_json = JSON.parse(json_string)
    #t_high = parsed_json['trip']['temp_high']['avg']["C"]
    #t_low = parsed_json['trip']['temp_low']['avg']["C"]
    #month_local_temp = ( t_high.to_f + t_low.to_f ) / 2
    #month_local_prec = parsed_json['trip']['precip']['avg']['cm'].to_f * 10
    
    #month_global_temp = get_wb_clim(var = "tas", country = :senegal, span = "month", ind = 8)
    #month_global_prec = get_wb_clim(var = "pr", country = :senegal, span = "month", ind = 8)
    #year_global_temp = get_wb_clim(var = "tas", country = :senegal, span = "year", ind = 2012)
    #year_global_prec = get_wb_clim(var = "pr", country = :senegal, span = "year", ind = 2012)
    #return {temp: year_global_temp, prec: year_global_prec}
    
    climate = Climate.where("(lat - 0.25) < ? AND (lat + 0.25) > ? AND (lon - 0.25) < ? AND (lon + 0.25) > ?", lat, lat, lon, lon).first
    return {temp: climate.temp/10.to_f, prec: climate.prec/10.to_f}
    
    
    #year_local_temp = month_local_temp * year_global_temp / month_global_temp
    #year_local_prec = month_local_prec * year_global_prec / month_global_prec
    #return {temp: year_local_temp, prec: year_local_prec}
    
    ####Old method of assembling each month - too many API calls
    # t = 0
    # t_ind = 0
    # p = 0
    # p_ind = 0
    # for i in 1..12
    #   j = i.to_s.rjust(2,'0')
    #   url = "http://api.wunderground.com/api/#{wunderground_key}/planner_#{j}01#{j}30/q/#{country}/#{city}.json"
    #   open(url) do |f|
    #     json_string = f.read
    #     parsed_json = JSON.parse(json_string)
    #     t_high = parsed_json['trip']['temp_high']['avg']["C"]
    #     t_low = parsed_json['trip']['temp_low']['avg']["C"]
    #     unless t_high == "" || t_low == ""
    #       temp = ( t_high.to_f + t_low.to_f ) / 2
    #       t = t + temp
    #       t_ind = t_ind + 1
    #     end
    #     precip = parsed_json['trip']['precip']['avg']['cm']
    #     unless precip == ""
    #       p = p + precip.to_f * 10
    #       p_ind = p_ind + 1
    #     end
    #     puts "#{i},#{temp},#{precip}"
    #   end
    # end
    # t = t / t_ind
    # p = p / p_ind * 12
    # return {temp: t, prec: p}
  end

  def self.get_wb_clim(var, country, span, ind)
    #note - annual pr is monthly average mm, not total
    url = "http://climatedataapi.worldbank.org/climateweb/rest/v1/country/cru/#{var}/#{span}/#{COUNTRY_HASH[country][:wb]}.json"
    json_string = open(url).read
    parsed_json = JSON.parse(json_string)
    ind = ind - 1901 if span == "year"
    value = parsed_json[ind]["data"]
  end
  
  def self.stats(arr)
    crop = arr[0]
    stat = arr[1]
    city = arr[2]
    
    #Get the climate data
    coords = TextMessage.get_coords(city)
    climate = TextMessage.get_climate(coords[:lat], coords[:lon])
    
    #get the model params
    model_params = ModelParameter.where(crop: crop.capitalize, statistic: stat.capitalize).first
    
    #estimate values based on location and model params
    beta = (JSON.parse model_params.estimated_params)["beta"]
    x_vals = [1.0, climate[:temp], climate[:prec], climate[:temp] ** 2, climate[:prec] ** 2, 2015]
    @mean = (0...beta.count).inject(0) {|r, i| r + beta[i]*x_vals[i]}
    @mean = @mean < 0 ? 0 : @mean
    @sd = Math.sqrt( (JSON.parse model_params.estimated_params)["sigma2"])
    return "#{(@mean).round} +/- #{(@sd).round} kg/ha"
  end
  
  private

  def client
    @client ||= Twilio::REST::Client.new
  end
  
  def phone_number
    @phone_number ||= Rails.application.secrets.twilio_phone_number
  end
  
end
