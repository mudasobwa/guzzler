require 'mongo'
module Guzzler
  module Spitter
    class Mongo
      include ::Mongo

      attr_reader :client

      def initialize *args
        @client = MongoClient.new(*args)
      end

      def db db
        return @db if @db && @db.name == db
        @db = client.db(db)
      end
    end
  end
end
