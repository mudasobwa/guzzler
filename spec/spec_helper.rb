$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'pry'
require 'rspec'
require 'guzzler'

RSpec.configure do |config|
  config.before(:each) do
  end
end
