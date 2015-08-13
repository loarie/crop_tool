class TextMessage < ActiveRecord::Base
  require 'open-uri'
  require 'json'
  
  after_create :process

  def process
    if to == "+"+phone_number.to_s
      code = body.split(",")
      error ||= true unless code.count >= 2
      error ||= true unless ["maize","millet"].include? code[0]
      error ||= true unless ["yield","planting","harvest"].include? code[1]
      error ||= true unless (code.count == 2 || (code.count == 3 && code[2].to_f != 0.0))
      
      if error
        new_sentence = "Error, we didn't understand #{body}"
      else
        if code.count == 2 #request
          new_sentence = "Our #{code[1]} estimate for #{code[0]} is #{stats(code)}"
        else #report
          Report.create(value: code[2].to_f, crop: code[0].capitalize, statistic: code[1].capitalize)
          new_sentence = "Thank you for submitting your request of #{body}"
        end
      end
      TextMessage.create(to: from, from: phone_number, body: new_sentence)
    else
      send_outgoing
    end
  end
  
  def stats(arr)
    climate = get_climate(13.880746, -13.183594)
    beta = [34213.331619,-3195.578803,183.478251,64.716467,-1.463032]
    sigma2 = 146643.8
    x_vals = [1, climate[temp:], climate[prec:], climate[temp:] ** 2, climate[prec:] ** 2]
    vec_prod = (0...beta.count).inject(0) {|r, i| r + beta[i]*x_vals[i]}
    @mean = ::CropModule::Maths.sum(vec_prod)
    return "#{(@mean).round} +/- #{(@sd).round} kg/ha"
    
    #@reports = Report.where(crop: arr[0].capitalize, statistic: arr[1].capitalize)
    #@values = @reports.map(&:value)
    #@mean = ::CropModule::Maths.mean(@values)
    #@mean = 0 if @mean.nan?
    #@sd = ::CropModule::Maths.standard_deviation(@values)
    #@sd = 0 if @sd.nan?
    #return "#{(@mean * 1000).round} +/- #{(@sd * 1000).round} kg/ha"
  end
  
  def send_outgoing
    client.messages.create(
      to: to,
      from: from,
      body: body
    )
  end
  
  def get_climate(lat, lon)
    wunderground_key = Rails.application.secrets.wunderground_key
    # json_string = open("http://api.wunderground.com/api/#{wunderground_key}/geolookup/q/#{lat},#{lon}.json").read
    # parsed_json = JSON.parse(json_string)
    # country = parsed_json["location"]["country_name"]
    # city = parsed_json["location"]["city"].gsub(" ","_")
    #
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
    return {temp: 30.0, prec: 34.0}
  end

  private

  def client
    @client ||= Twilio::REST::Client.new
  end
  
  def phone_number
    @phone_number ||= Rails.application.secrets.twilio_phone_number
  end
  
end
