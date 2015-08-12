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
        new_sentence = "Error #{body}"
      else
        if code.count == 2 #request
          new_sentence = "The mean #{body}"
        else #report
          Report.create(value: code[2].to_f, crop: code[0].capitalize, statistic: code[1].capitalize)
          new_sentence = "Thank you #{body}"
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

  private

  def client
    @client ||= Twilio::REST::Client.new
  end
  
  def phone_number
    @phone_number ||= Rails.application.secrets.twilio_phone_number
  end
end
