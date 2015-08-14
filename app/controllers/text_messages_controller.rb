class TextMessagesController < ApplicationController
  require 'json'
  
  skip_before_action :verify_authenticity_token

    def create
      #puts params[:FromZip]
      TextMessage.create(message_attributes)
      head :ok
    end

    private

    def message_attributes
      { to: params[:To], 
      from: params[:From], 
      body: params[:Body].strip.downcase }
    end
end
