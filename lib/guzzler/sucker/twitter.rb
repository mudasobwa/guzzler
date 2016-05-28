require 'yaml'
require 'twitter'

module Guzzler
  module Sucker
    class Credentials
      class << self
        require 'pry'
        ALL = Dir[File.join File.dirname(__FILE__), "../../../data/twitter/**/*"].each_with_object({}) do |f, memo|
          memo[File.basename(f).to_sym] = YAML.load_file f
        end
        def get name = nil, except: @current
          @current = name ? ALL[name] : loop.detect do
                                          result = ALL.to_a.sample
                                          break result.last unless result.first == except
                                        end
        end
      end
    end

    class Twitter
      attr_reader :client

      def initialize credentials: nil, live: false
        @client = (live ? ::Twitter::Streaming::Client : ::Twitter::REST::Client).new do |config|
          tokens = Credentials.get credentials, except: nil
          config.consumer_key        = tokens['CONSUMER_KEY']
          config.consumer_secret     = tokens['CONSUMER_SECRET']
          config.access_token        = tokens['ACCESS_TOKEN']
          config.access_token_secret = tokens['ACCESS_SECRET']
          # config.bearer_token        = tokens['CONSUMER_BEARER'] if config.respond_to? :bearer_token
        end
      end
    end
  end
end
