require 'spec_helper'

TEST_DATABASE = 'zyzzy_test'.freeze

describe Guzzler::Spitter::Driver do
  subject { Guzzler::Spitter::Driver }
  let!(:driver) { :mongo }
  let!(:params) { ['localhost', 27_017] }

  before do
    subject.new(driver: driver, params: params).mongo.client.drop_database TEST_DATABASE
  end

  it 'can create a connection to mongo instance' do
    conn = subject.new(driver: driver, params: params)
    expect(conn.inspect).to include('@host="localhost", @port=27017')
  end

  it 'can connect to mongo database' do
    conn = subject.new(driver: driver, params: params)
    expect(conn.mongo.db(TEST_DATABASE).inspect).to include('@host="localhost", @port=27017')
  end

  it 'can store and retrieve values from mongo collection' do
    conn = subject.new(driver: driver, params: params)
    coll = conn.mongo.db(TEST_DATABASE)["testCollection"]
    coll.insert answer: 42, question: nil
    expect(conn.mongo.db(TEST_DATABASE).collection_names).to include "testCollection"
    expect(coll.find(answer: 42).to_a).not_to be_empty
    expect(coll.find(answer: 42).to_a.last).to be_a(Hash)
    expect(coll.find(answer: 42).to_a.last).to be_has_key('question')
  end
end
