require 'spec_helper'

describe Guzzler::Sucker::Driver do
  subject { Guzzler::Sucker::Driver }
  let!(:driver) { :twitter }
  let!(:params) { [] }

  before do
    @client = subject.new(driver: driver, params: params).twitter.client
    @client.user('mudasobwa')
  end

  it 'may read from twitter' do
    expect(@client.bearer_token).not_to be_nil
  end

  it 'may read from closest trends' do
    bcn = @client.trends_closest(Guzzler::BCN_GEO.dup).first
    expect(@client.trends(bcn.id).each.to_a).not_to be_empty
  end

  it 'may search by keyword, geocode and language' do
    results = @client.search  '#ruby -rt',
                              geocode: "#{Guzzler::BCN_GEO[:lat]},#{Guzzler::BCN_GEO[:long]},50km",
                              lang: 'en'
    expect(results.count).to be > 0
  end

  it 'may search by keyword, ending with given date' do
    results = @client.search  '#ruby -rt',
                              lang: 'en',
                              max_id: '2016053301'
    expect(results.count).to be > 0
  end
end
