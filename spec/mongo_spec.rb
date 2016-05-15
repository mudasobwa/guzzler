require 'spec_helper'

TEST_DATABASE = 'zyzzy_test'.freeze
TEST_COLLECTION = 'test_collection'.freeze

describe Guzzler::Spitter::Driver do
  subject { Guzzler::Spitter::Driver }
  let!(:driver) { :mongo }
  let!(:params) { "mongodb://127.0.0.1:27017/#{Guzzler::DATABASE}" }

  before do
    subject.new(driver: driver, params: params).mongo.client[TEST_COLLECTION].drop
  end

  it 'can connect to mongo database' do
    conn = subject.new(driver: driver, params: params)
    expect(conn.inspect).to include('cluster=127.0.0.1:27017')
  end

  it 'can store and retrieve values from mongo collection' do
    conn = subject.new(driver: driver, params: params)
    coll = conn.mongo.client[TEST_COLLECTION]
    coll.insert_one answer: 42, question: nil
    # expect(conn.mongo.client.collection_names).to include TEST_COLLECTION
    expect(coll.find(answer: 42).to_a).not_to be_empty
    expect(coll.find(answer: 42).to_a.last).to be_a(Hash)
    expect(coll.find(answer: 42).to_a.last).to be_has_key('question')
  end

  it 'creates an index on the field' do
    conn = subject.new(driver: driver, params: params)
    coll = conn.mongo.client[TEST_COLLECTION]
    coll.insert_one answer: 42, question: nil
    coll.indexes.create_one({ answer: 1 }, unique: true)
  end

  it 'searches by an index on the field' do
    conn = subject.new(driver: driver, params: params)
    coll = conn.mongo.client[TEST_COLLECTION]
    coll.insert_one answer: 42, question: "a"
    coll.insert_one answer: 43, question: nil
    coll.insert_one answer: 44, question: nil
    coll.insert_one answer: 45, question: "b"
    coll.indexes.create_one({ answer: 1 }, unique: true)
    expect(coll.find.sort(answer: 1).limit(1).first['question']).to eq 'a'
    expect(coll.find.sort(answer: -1).limit(1).first['question']).to eq 'b'
  end
end
