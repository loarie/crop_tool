class TextMessage < ActiveRecord::Base
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
    @reports = Report.where(crop: arr[0], statistic: arr[1])
    @values = @reports.map(&:value)
    @mean = ::CropModule::Maths.mean(@values)
    @mean = 0 if @mean.nan?
    @sd = ::CropModule::Maths.standard_deviation(@values)
    @sd = 0 if @sd.nan?
    return "#{(@mean * 1000).round} +/- #{(@sd * 1000).round} kg/ha"
  end
  
  def send_outgoing
    client.messages.create(
      to: to,
      from: from,
      body: body
    )
  end

  private

  def client
    @client ||= Twilio::REST::Client.new
  end
  
  def phone_number
    @phone_number ||= Rails.application.secrets.twilio_phone_number
  end
end
