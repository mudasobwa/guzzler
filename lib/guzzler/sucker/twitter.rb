require 'twitter'

module Guzzler
  module Sucker
    class Twitter
      CONSUMER_KEY    = 'Ks0RLhhdzv1UlQtl8WF758aVm'.freeze
      CONSUMER_SECRET = '0AY7V3s6Hc1EsfMkgMSf5TAQbXq7sWftSuIkP20uWOm4iuKfn1'.freeze
      CONSUMER_BEARER = 'AAAAAAAAAAAAAAAAAAAAALysvAAAAAAA0piRKfQaWRsk0p%2FUVkL58tgLWM0%3DKNxi9brbgO63WoZTBgxZhZtfGZDZqjebmAB6yFG241JgIF1wkJ'.freeze

      ACCESS_TOKEN    =	'182232382-hwmgInNeD5KdiLibZEyP5eK8xG1QhO8JJTqcXhZv'.freeze
      ACCESS_SECRET   =	'ZYekR81eOGauPEAlgLK67J2QFxa1Zhvg5AdqxAqw7ed1J'.freeze

      OWNER           =	'mudasobwa'.freeze
      OWNER_ID        = 182_232_382

      attr_reader :client

      def initialize live: false
        @client = (live ? ::Twitter::Streaming::Client : ::Twitter::REST::Client).new do |config|
          config.consumer_key        = CONSUMER_KEY
          config.consumer_secret     = CONSUMER_SECRET
          config.access_token        = ACCESS_TOKEN
          config.access_token_secret = ACCESS_SECRET
          config.bearer_token        = CONSUMER_BEARER if config.respond_to? :bearer_token
        end
      end
    end
  end
end
