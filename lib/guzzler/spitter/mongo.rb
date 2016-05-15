require 'mongo'
require 'logger'

module Guzzler
  module Spitter
    class Mongo
      include ::Mongo

      attr_reader :client

      def initialize *args
        Mongo::Logger.logger.level = ::Logger::WARN
        @client = Mongo::Client.new(*args)
      end
    end
  end
end
