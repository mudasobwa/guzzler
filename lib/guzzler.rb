require 'guzzler/version'
require 'guzzler/spitter'
require 'guzzler/sucker'

module Guzzler
  BCN_GEO = { lat: 41.390205, long: 2.154007 }.freeze
  BCN_RECTANGLE = '2.03,41.34,2.25,41.45'.freeze
  SPAIN_RECTANGLE = '-6.52,36.88,3.61,43.56'.freeze
  DATABASE = 'guzzler'.freeze

  # FIXME: INDEX !!!
  def self.recordset collection
    Guzzler::Spitter::Driver.new(driver: :mongo).mongo.client[collection.to_s]
  end

  def self.connect collection, live: false
    [
      Guzzler::Sucker::Driver.new(driver: :twitter, live: live).twitter.client,
      mongo = recordset(collection),
      (mongo.find.sort(created_at: 1).limit(1).first rescue nil),
      mongo.find.count
    ]
  end

  def self.get_tag tag, lang: :en, from: nil, collection: :guzzler
    get_tweets "##{tag}", lang: lang, from: from, collection: collection
  end

  def self.get_tweets query, lang: :en, from: nil, collection: :guzzler
    loop do
      begin
        twitter, mongo, last, counter = connect collection
        break if last && DateTime.parse(last['created_at']) < (Date.parse('2016-05-15') - 365).to_datetime

        from ||= last

        hash = { lang: lang.to_s, result_type: 'recent' }
        hash[:max_id] = last['id'] if last

        puts "Dealing with: #{last}"

        twitter.search(
          "#{query} -rt", hash
          # uncomment the following line to get it in BCN
          # geocode: "#{Guzzler::BCN_GEO[:lat]},#{Guzzler::BCN_GEO[:long]},50km"
        ).each do |res| # .take(hash[:count]) ??
          next unless res.text && res.text.length > 4
          mongo.insert_one res.to_h
          counter += 1
          puts "#{counter.to_s.rjust(10)} records. Latest: #{res.created_at}" if (counter % 200).zero?
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

  def self.live_tweets keywords = [], collection: :guzzler_live
    loop do
      begin
        twitter, mongo, _, counter = connect collection, live: true

        # twitter.filter(locations: SPAIN_RECTANGLE) do |tweet|
        # twitter.filter(track: keywords.join(',')) do |tweet|
        params = !keywords.empty? ? { track: keywords.join(',') } : { locations: BCN_RECTANGLE }
        twitter.filter(params) do |tweet|
          puts "[NFO] received: #{tweet.text}" if (counter % 200).zero?
          next unless tweet.is_a?(Twitter::Tweet) && %w(en ru).include?(tweet.lang)
          counter += 1
          mongo.insert_one tweet.to_h
          user_tweets tweet.user.id # FIXME: Thread.new
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

  # db.getCollection('guzzler_live').find({geo: {$ne: null}})
  # db.getCollection('guzzler_live').find({place: {name: 'Barcelona'}})
  def self.user_tweets user, collection: :history
    twitter, mongo, = connect collection, live: false

    tweets = loop.each_with_object([]) do |_, memo|
      params = { count: 200, include_rts: true }
      params[:max_id] = memo.last['max_id'] unless memo.empty?
      memo |= twitter.user_timeline(user, params)
      break memo if memo.last.created_at < (Date.today - 14).to_datetime
    end

    if tweets.any? { |t| t.user && /Barcelona/i !~ t.user.location || t.place && /Barcelona/i !~ t.place.name }
      # next unless tweet.is_a?(Twitter::Tweet) # && %w(en ru).include?(tweet.lang)
      puts "[HIST]: Updated for #{user}"
      mongo.insert_many(tweets.map(&:to_h))
    end
  end
end
