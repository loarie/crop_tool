class ModelParametersController < ApplicationController
  def estimate
    params[:crop] ||= "Maize"
    params[:statistic] ||= "Yield"
    params[:city] ||= "Accra"
    crop = params[:crop]
    stat = params[:statistic]
    city = params[:city]
    @estimate = TextMessage.stats([crop,stat,city])
  end
end