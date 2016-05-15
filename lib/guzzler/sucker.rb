module Guzzler
  module Sucker
    class Driver
      attr_reader :conn

      def initialize driver: :twitter, params: []
        require "guzzler/sucker/#{driver}"
        # rubocop:disable Style/PerlBackrefs
        conn_class = Kernel.const_get("Guzzler::Sucker::#{driver.to_s.gsub(/(_|^)(\w)/) { $2.upcase }}")
        # rubocop:enable Style/PerlBackrefs
        @conn = conn_class.new(*params)
        self.class.send :define_method, driver do
          conn
        end
      end
    end
  end
end
