class TextMessage < ActiveRecord::Base
  require 'open-uri'
  
  after_create :process

  COUNTRY_HASH = {senegal: {wb: 'SEN', go: 'sn', pretty: 'Senegal'}}
  CROPS = ["maize","millet"]
  STATISTICS = ["yield","planting","harvest"]
  
  def process
    if to == "+"+phone_number.to_s
      code = body.split(",")
      error ||= true unless code.count >= 3
      error ||= true unless CROPS.include? code[0]
      error ||= true unless STATISTICS.include? code[1]
      error ||= true unless (code.count == 3 || (code.count == 4 && code[3].to_f != 0.0))
      
      if error
        new_sentence = "Error, we didn't understand #{body}"
      else
        if code.count == 3 #request
          
          new_sentence = "Our #{code[1]} estimate for #{code[0]} is #{stats(code)}"
          
        else #reporting data
          crop = code[0].capitalize
          stat = code[1].capitalize
          city = code[2]
          val = code[3].to_f
          
          coords = get_coords(city)
          climate = get_climate(coords["lat"], coords["lon"])
    
          Report.create(country: COUNTRY_HASH[:senegal][:pretty], city: city, lat: coords["lat"], lon: coords["lon"], crop: crop, statistic: stat, value: val, temp: climate["temp"], prec: climate["prec"], identity: to)
          new_sentence = "Thank you for submitting your request of #{body}"
          
          update_model(COUNTRY_HASH[:senegal][:pretty], crop, stat)
          
        end
      end
      TextMessage.create(to: from, from: phone_number, body: new_sentence)
    else
      send_outgoing
    end
  end
  
  def stats(arr)
    crop = arr[0]
    stat = arr[1]
    city = arr[2]
    
    #Get the climate data
    coords = get_coords(city)
    climate = get_climate(coords["lat"], coords["lon"])
    
    #get the model params
    model_params = ModelParameter.where(country: COUNTRY_HASH[:senegal][:pretty], crop: crop, statistic: stat).first
    
    #estimate values based on location and model params
    beta = (JSON.parse model_params.estimated_params)["beta"]
    x_vals = [1.0, climate[:temp], climate[:prec], climate[:temp] ** 2, climate[:prec] ** 2]
    @mean = (0...beta.count).inject(0) {|r, i| r + beta[i]*x_vals[i]}
    @sd = Math.sqrt( (JSON.parse model_params.estimates)["sigma2"])
    return "#{(@mean).round} +/- #{(@sd).round} kg/ha"
  end
  
  def send_outgoing
    client.messages.create(
      to: to,
      from: from,
      body: body
    )
  end
  
  def update_model(country, crop, stat)
    #get_priors
    mp = ModelParameter.where(country: country, crop: crop, statistic: stat).first
    prirors = mp.priors
    b0 = priors[:b0].to_s.gsub("[","c(").gsub("]",")")
    
    #get_data
    data = Report.where(country: country, crop: crop, statistic: stat)
    y = data.map(&:value).to_s.gsub("[","c(").gsub("]",")")
    x1 = data.map(&:temp).to_s.gsub("[","c(").gsub("]",")")
    x2 = data.map(&:precip).to_s.gsub("[","c(").gsub("]",")")
    
    #update the model
    input_params = {'b0' => b0, 'Vbcoef' => priors[:Vbcoef], 's1' => priors[:s1], 's2' => priors[:s2], 'y' => y, 'x1' => x1, 'x2' => x2}
    ocpu_call = Net::HTTP.post_form(URI.parse('http://104.236.132.146/ocpu/library/cropmodel/R/crop_function'), input_params)
    ocpu_dir = ocpu_call.body.split("/")[3]
    ocpu_response = Net::HTTP.get(URI.parse("http://104.236.132.146/ocpu/tmp/#{ocpu_dir}/stdout/text"))
    output_params = ocpu_response.split("\"")[1].gsub("beta","\"beta\"").gsub("sigma2","\"sigma2\"")
    
    #update database
    mp.estimated_params = output_params
    mp.save
  end
  
  def get_coords
    google_key = Rails.application.secrets.google_key
    url = "https://maps.googleapis.com/maps/api/geocode/json?address=#{city}&region=#{COUNTRY_HASH[:senegal][:go]}&key=#{google_key}"
    json_string = open(url).read
    parsed_json = JSON.parse(json_string)
    parsed_json["results"][0]["geometry"]["location"]
  end
  
  def get_climate(lat, lon)
    wunderground_key = Rails.application.secrets.wunderground_key
    json_string = open("http://api.wunderground.com/api/#{wunderground_key}/geolookup/q/#{lat},#{lon}.json").read
    parsed_json = JSON.parse(json_string)
    country = parsed_json["location"]["country_name"]
    city = parsed_json["location"]["city"].gsub(" ","_")
    
    url = "http://api.wunderground.com/api/#{wunderground_key}/planner_08010830/q/#{country}/#{city}.json"
    json_string = open(url).read
    parsed_json = JSON.parse(json_string)
    t_high = parsed_json['trip']['temp_high']['avg']["C"]
    t_low = parsed_json['trip']['temp_low']['avg']["C"]
    month_global_temp = ( t_high.to_f + t_low.to_f ) / 2
    month_global_prec = parsed_json['trip']['precip']['avg']['cm'].to_f * 10
    
    month_global_temp = get_wb_clim(var = "tas", country = :senegal, span = "month", ind = 8)
    month_global_prec = get_wb_clim(var = "pr", country = :senegal, span = "month", ind = 8)
    year_global_temp = get_wb_clim(var = "tas", country = :senegal, span = "year", ind = 2012)
    year_global_prec = get_wb_clim(var = "pr", country = :senegal, span = "year", ind = 2012)
    
    year_local_temp = month_local_temp * year_global_temp / month_global_temp
    year_local_prec = month_local_prec * year_global_prec / month_global_prec
    return {temp: year_local_temp, prec: year_local_prec}
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

  def get_wb_clim(var, country, span, ind)
    url = "http://climatedataapi.worldbank.org/climateweb/rest/v1/country/cru/#{var}/#{span}/#{COUNTRY_HASH[country][:wb]}.json"
    json_string = open(url).read
    parsed_json = JSON.parse(json_string)
    ind = ind - 1901 if span == "year"
    value = parsed_json[ind]["data"]
  end
  
  private

  def client
    @client ||= Twilio::REST::Client.new
  end
  
  def phone_number
    @phone_number ||= Rails.application.secrets.twilio_phone_number
  end
  
end
