require 'guzzler/version'
require 'guzzler/spitter'
require 'guzzler/sucker'

module Guzzler
  BCN_GEO = { lat: 41.390205, long: 2.154007 }.freeze
  BCN_RECTANGLE = '41.34,2.03,41.45,2.25'.freeze
  SPAIN_RECTANGLE = '36.88,-6.52,43.56,3.61'.freeze
  DATABASE = 'guzzler'.freeze

  # FIXME INDEX !!!
  def self.connect collection
    [
      Guzzler::Sucker::Driver.new(driver: :twitter).twitter.client,
      Guzzler::Spitter::Driver.new(driver: :mongo).mongo.client[collection.to_s],
      (mongo.find.sort(created_at: 1).limit(1).first['id'] rescue nil),
      mongo.find.count
    ]
  end

  def self.get_tag tag, lang: :en, from: nil, collection: :guzzler
    get_tweets "##{tag}", lang: lang, from: from, collection: collection
  end

  def self.get_tweets query, lang: :en, from: nil, collection: :guzzler
    loop do
      twitter, mongo, last, counter = connect collection
      break if last && last.created_at < (Date.today - 365).to_time

      from ||= last

      hash = { lang: lang.to_s, result_type: 'recent' }
      hash[:max_id] = last.id if last

      begin
        twitter.search(
          "#{query} -rt", hash
          # uncomment the following line to get it in BCN
          # geocode: "#{Guzzler::BCN_GEO[:lat]},#{Guzzler::BCN_GEO[:long]},50km"
        ).each do |res| # .take(hash[:count]) ??
          next unless res.text && res.text.length > 4
          mongo.insert_one r.to_h
          counter += 1
          puts "#{counter.to_s.rjust(10)} records aggregated" if (counter % 200).zero?
        end
      rescue Twitter::Error::TooManyRequests => error
        puts "[ERR] #{error.rate_limit.reset_in.to_s.rjust(10)} seconds to wait..."
        # puts error.rate_limit.inspect
        sleep error.rate_limit.reset_in + 1
      rescue => error
        puts "[ERR] #{error.inspect}"
        sleep 60
      end

      from = nil
    end
  end

  def self.live_tweets keywords, collection: :guzzler_live
    loop do
      twitter, mongo, _, counter = connect collection

      begin
        # twitter.filter(locations: SPAIN_RECTANGLE) do |tweet|
        # twitter.filter(track: keywords.join(',')) do |tweet|
        twitter.filter(locations: BCN_RECTANGLE, track: keywords.join(',')) do |tweet|
          puts "[NFO] received: #{tweet.text}" if (counter % 200).zero?
          counter += 1
          next unless tweet.is_a?(Twitter::Tweet) && %w(en ru).include?(tweet.lang)
          mongo.insert_one tweet.to_h
        end
      rescue Twitter::Error::TooManyRequests => error
        puts "[ERR] #{error.rate_limit.reset_in.to_s.rjust(10)} seconds to wait..."
        # puts error.rate_limit.inspect
        sleep error.rate_limit.reset_in + 1
      rescue => error
        puts "[ERR] #{error.inspect}"
        puts error.backtrace.join $/
        sleep 60
      end
    end
  end
end
