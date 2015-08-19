require 'twilio-ruby'
 
class TwilioController < ApplicationController
  include Webhookable
 
  after_filter :set_header
 
  skip_before_action :verify_authenticity_token
 
  def voice
    response = Twilio::TwiML::Response.new do |r|
      r.Say 'Afin de répondre à la question de l’emploi des jeunes qui est d’une grande acuité pour la sous région de l’Afrique de l’Ouest et du Centre, le CORAF/WECARD a sollicité l’appui financier de  la Banque Islamique de Développement (BID) pour initier le projet «Soutien au lancement de la connaissance pour l’Emplois de jeunes à travers le Canal Web ». La mise en œuvre de ce projet a nécessité la contribution financière du  Programme de productivité Agricole en Afrique de l’Ouest (PPAAO/WAAPP). Ce projet vise comme objectif général d’accroître l’utilisation des résultats de recherche à travers l’internet en tant que source d’opportunités de nouveaux emplois pour les Jeunes scolarisés.', :voice => 'alice'
         r.Play 'http://linode.rabasa.com/cantina.mp3'
    end
 
    render_twiml response
  end
end
