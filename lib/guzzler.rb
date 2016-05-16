require 'guzzler/version'
require 'guzzler/spitter'
require 'guzzler/sucker'

module Guzzler
  BCN_GEO = { lat: 41.390205, long: 2.154007 }.freeze
  BCN_RECTANGLE = '41.34,2.03,41.45,2.25'.freeze
  SPAIN_RECTANGLE = '36.88,-6.52,43.56,3.61'.freeze
  DATABASE = 'guzzler'.freeze

  def self.get_tag tag, lang: :en, from: nil, collection: :guzzler
    get_tweets "##{tag}", lang: lang, from: from, collection: collection
  end

  def self.get_tweets query, lang: :en, from: nil, collection: :guzzler
    twitter = Guzzler::Sucker::Driver.new(driver: :twitter).twitter.client
    mongo = Guzzler::Spitter::Driver.new(driver: :mongo).mongo.client[collection.to_s]

    from ||= mongo.find.sort(created_at: 1).limit(1).first['id'] rescue nil

    counter = 0
    loop.inject(from) do |memo|
      # hash = { lang: lang.to_s, count: 100, result_type: 'recent' }
      hash = { lang: lang.to_s, result_type: 'recent' }
      # rubocop:disable Performance/RedundantMerge
      # hash.merge!(max_id: memo, since_id: memo - hash[:count]) if memo
      hash.merge!(max_id: memo) if memo
      # rubocop:enable Performance/RedundantMerge
      begin
        last = twitter.search(
          "#{query} -rt", hash
          # uncomment the following line to get it in BCN
          # geocode: "#{Guzzler::BCN_GEO[:lat]},#{Guzzler::BCN_GEO[:long]},50km"
        ).inject(nil) do |rmemo, res| # .take(hash[:count]) ??
          next rmemo unless res.text && res.text.length > 4
          res.tap do |r|
            mongo.insert_one r.to_h
            counter += 1
            puts "#{counter.to_s.rjust(10)} records aggregated" if (counter % 200).zero?
          end
        end
      rescue Twitter::Error::TooManyRequests => error
        puts "[ERR] #{error.rate_limit.reset_in.to_s.rjust(10)} seconds to wait..."
        # puts error.rate_limit.inspect
        sleep error.rate_limit.reset_in + 1
        retry
      rescue => error
        puts "[ERR] #{error.inspect}"
        sleep 60
        retry
      end

      break memo if last && last.created_at < (Date.today - 365).to_time
      last.nil? ? mongo.find.sort(created_at: 1).limit(1).first['id'] : last.id
    end
  end

  def self.live_tweets keywords, collection: :guzzler_live
    twitter = Guzzler::Sucker::Driver.new(driver: :twitter, live: true).twitter.client
    mongo = Guzzler::Spitter::Driver.new(driver: :mongo).mongo.client[collection.to_s]
    counter = 0

    begin
      # twitter.filter(locations: SPAIN_RECTANGLE) do |tweet|
      # twitter.filter(track: keywords.join(',')) do |tweet|
      twitter.filter(locations: BCN_RECTANGLE, track: keywords.join(',')) do |tweet|
        puts "[NFO] received: #{tweet.text}" if (counter % 200).zero?
        counter += 1
        next unless tweet.is_a? Twitter::Tweet
        mongo.insert_one tweet.to_h
      end
    rescue Twitter::Error::TooManyRequests => error
      puts "[ERR] #{error.rate_limit.reset_in.to_s.rjust(10)} seconds to wait..."
      # puts error.rate_limit.inspect
      sleep error.rate_limit.reset_in + 1
      retry
    rescue => error
      puts "[ERR] #{error.inspect}"
      puts error.backtrace.join $/
      sleep 60
      retry
    end
  end
end
