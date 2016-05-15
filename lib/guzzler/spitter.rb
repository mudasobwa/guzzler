module Guzzler
  module Spitter
    class Driver
      attr_reader :conn

      def initialize driver: :mongo, params: "mongodb://127.0.0.1:27017/#{Guzzler::DATABASE}"
        require "guzzler/spitter/#{driver}"
        # rubocop:disable Style/PerlBackrefs
        conn_class = Kernel.const_get("Guzzler::Spitter::#{driver.to_s.gsub(/(_|^)(\w)/) { $2.upcase }}")
        # rubocop:enable Style/PerlBackrefs
        @conn = conn_class.new(params)
        self.class.send :define_method, driver do
          conn
        end
      end
    end
  end
end
