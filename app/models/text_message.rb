class TextMessage < ActiveRecord::Base
  after_create :process

  def process
    if to == "+"+phone_number.to_s
      #new_sentence = body.split.map{ |x| translate(x) }
      #new_sentence = new_sentence.join(" ")
      #TextMessage.create(to: from, from: phone_number, body: new_sentence)
      code = body.split(",")
      error ||= true unless code.count >= 2
      error ||= true unless ["Maize","Millet"].include? code[0]
      error ||= true unless ["Yield","Planting","Harvest"].include? code[1]
      error ||= true unless code.count == 2 || (code.count == 3 && code[2].to_f == 0.0)
      
      if error
        new_sentence = "Error"
      else
        if code.count == 2 #request
          new_sentence = "The mean"
        else #report
          #save the record
          new_sentence = "Thank you"
        end
      end
      TextMessage.create(to: from, from: phone_number, body: new_sentence)
    else
      send_outgoing
    end
  end
  
  def translate(str)
    alpha = ('a'..'z').to_a
    vowels = %w[a e i o u]
    consonants = alpha - vowels

    if vowels.include?(str[0])
      str + 'ay'
    elsif consonants.include?(str[0]) && consonants.include?(str[1])
      str[2..-1] + str[0..1] + 'ay'
    elsif consonants.include?(str[0])
      str[1..-1] + str[0] + 'ay'
    else
      str
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
