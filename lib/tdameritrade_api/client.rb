require 'net/http'
require 'openssl'
require 'tmpdir'
require 'bindata'
require 'httparty'
require 'date'
require 'tdameritrade_api/bindata_types'
require 'tdameritrade_api/exception'
require 'tdameritrade_api/watchlist'

module TDAmeritradeApi
  class Client
    include BinDataTypes
    include Watchlist

    attr_accessor :session_id, :source_id, :user_id, :password

    PRICE_HISTORY_URL='https://apis.tdameritrade.com/apps/100/PriceHistory'
    INTERVAL_TYPE=[:minute, :daily, :weekly, :monthly]
    PERIOD_TYPE=[:day, :month, :year, :ytd]

    def initialize
      self.source_id=ENV['TDAMERITRADE_SOURCE_KEY']
      self.user_id=ENV['TDAMERITRADE_USER_ID']
      self.password=ENV['TDAMERITRADE_PASSWORD']
    end

    def login
      uri = URI.parse("https://apis.tdameritrade.com/apps/100/LogIn?source=#{@source_id}&version=1.0.0")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(uri.path)
      request.add_field('Content-Type', 'application/x-www-form-urlencoded')
      request.body = "userid=#{@user_id}&password=#{@password}&source=#{@source_id}&version=1.0.0"
      result = http.request(request)
      #puts result.body

      login_result = result.body.scan(/<result>(.*)<\/result>/).first.first
      login_result = login_result == "OK" ? true : false
      if login_result
        self.session_id=result.body.scan(/<session-id>(.*)<\/session-id>/).first.first
      end

      login_result
    end

    # +get_price_history+ allows you to send a price history request. For now it can only accommodate one
    # symbol at a time. +options+ may contain any of the following params outlined in the API docs
    # * periodtype: (:day, :month, :year, :ytd)
    # * period: number of periods for which data is returned
    # * intervaltype (:minute, :daily, :weekly, :monthly)
    # * intervalduration
    # * startdate
    # * enddate
    # * extended: true/false
    def get_price_history(symbol, options={})
      # TODO: allow multiple symbols by allowing user to pass and array of strings
      # TODO: change this around so that it does not need a temporary file buffer and can handle the processing in memory
      validate_price_history_options options
      request_params = build_price_history_request_params(symbol, options)

      uri = URI.parse PRICE_HISTORY_URL
      uri.query = URI.encode_www_form(request_params)

      response = HTTParty.get(uri, headers: {'Cookie' => "JSESSIONID=#{@session_id}"}, timeout: 10)
      if response.code != 200
        raise TDAmeritradeApiError, "HTTP response #{response.code}: #{response.body}"
      end

      tmp_file=File.join(Dir.tmpdir, "daily_prices.binary")
      w = open(tmp_file, 'wb')
      w.write(response.body)
      w.close
      rd = open(tmp_file, 'rb')

      header = PriceHistoryHeader.read(rd)
      #puts "#{header.symbol}: #{header.bar_count} bars"

      if header.error_code != 0
        return [{ :error => "#{header.error_code}: #{header.error_text}" }]
      end

      prices = Array.new
      while rd.read(2).bytes != [255,255]   # The terminator char is "\xFF\xFF"
        rd.seek(-2, IO::SEEK_CUR)
        bar = PriceHistoryBarRaw.read(rd)
        prices << {
            open: bar.open.round(2),
            high: bar.high.round(2),
            low: bar.low.round(2),
            close: bar.close.round(2),
            volume: bar.volume.round(2), # volume is presented in 100's, per TD Ameritrade API spec
            timestamp: Time.at(bar.timestampint/1000),
            interval: :day
        }
        #puts "#{bar.open} #{bar.high} #{bar.low} #{bar.close} #{Time.at(bar.timestampint/1000)}"
      end

      prices

    rescue Exception => e
      raise TDAmeritradeApiError, "error in get_price_history() - #{e.message}" if !e.is_ctrl_c_exception?
    end

    # +get_daily_price_history+ is a shortcut for +get_price_history()+ for getting a series of daily price candles
    # It adds convenience because you can just specify a begin_date and end_date rather than all of the
    # TDAmeritrade API parameters.
    def get_daily_price_history(symbol, start_date=Date.new(2001,1,2), end_date=todays_date)
      get_price_history(symbol, intervaltype: :daily, intervalduration: 1, startdate: start_date, enddate: end_date)
    end

    # +get_minute_price_history+ will soon be a legacy function. use +get_price_history+ instead
    def get_minute_price_history(symbol, interval={})
      if interval.has_key?(:days_back) then
        # for it to get today's data, you have to set the enddate parameter to today
        # See forum post #10597
        uri = URI.parse("https://apis.tdameritrade.com/apps/100/PriceHistory?source=#{@source_id}&requestidentifiertype=SYMBOL&requestvalue=#{symbol}&intervaltype=MINUTE&intervalduration=1&periodtype=DAY&period=#{days_back}&extended=true&enddate=#{todays_date}")
      else
        begin_date = interval[:begin_date] || '20140101'
        end_date = interval[:end_date] || todays_date
        uri = URI.parse("https://apis.tdameritrade.com/apps/100/PriceHistory?source=#{@source_id}&requestidentifiertype=SYMBOL&requestvalue=#{symbol}&intervaltype=MINUTE&intervalduration=1&extended=true&startdate=#{begin_date}&enddate=#{end_date}")
      end

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new uri
      request['Set-Cookie'] = "JSESSIONID=#{@session_id}"
      response = http.request request



      if response.code != "200"
        return [{ :error => "#{response.code}: #{response.body.encode('utf-8')}"}]
      end

      tmp_file=File.join(Dir.tmpdir, "minute_prices.binary")
      download_file = open(tmp_file, 'wb')
      download_file.write(response.body)
      download_file.close
      rd = open(tmp_file, 'rb')

      header = PriceHistoryHeader.read(rd)
      #puts "#{header.symbol}: #{header.bar_count} bars"

      if header.error_code != 0
        return [{ :error => "#{header.error_code}: #{header.error_text}" }]
      end

      prices = Array.new
      while rd.read(2).bytes != [255,255]   # The terminator char is "\xFF\xFF"
        rd.seek(-2, IO::SEEK_CUR)
        bar = PriceHistoryBarRaw.read(rd)
        prices << {
            open: bar.open.round(2),
            high: bar.high.round(2),
            low: bar.low.round(2),
            close: bar.close.round(2),
            volume: bar.volume,
            timestamp: Time.at(bar.timestampint/1000),
            interval: :minute
        }
        #puts "#{bar.open} #{bar.high} #{bar.low} #{bar.close} #{Time.at(bar.timestampint/1000)}"
      end

      prices
    end

    # this currently only works on stocks
    def get_quote(symbols)
      if symbols.is_a? Array
        quote_list = symbols.join(',') if symbols.is_a? Array
      else
        quote_list=symbols
      end

      uri = URI.parse("https://apis.tdameritrade.com/apps/100/Quote;jsessionid=#{@session_id}?source=#{@source_id}&symbol=#{quote_list}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new uri
      request['Set-Cookie'] = "JSESSIONID=#{@session_id}"

      begin
      response = http.request request
      rescue
        puts "error here in api- get_quote function"
      end
      #puts response.body

      quotes = Array.new
      q = Nokogiri::XML::Document.parse response.body
      q.css('quote').each do |q|
        quotes << {
          symbol: q.css('symbol').text,
          bid: q.css('bid').text,
          ask: q.css('ask').text,
          bid_ask_size: q.css('bid-ask-size').text,
          last: q.css('last').text,
          last_trade_size: q.css('last-trade-size').text,
          last_trade_time: parse_last_trade_date(q.css('last-trade-date').text),
          open: q.css('open').text,
          high: q.css('high').text,
          low: q.css('low').text,
          close: q.css('close').text,
          volume: q.css('volume').text,
          real_time: q.css('real-time').text,
          change: q.css('change').text,
          change_percent: q.css('change-percent').text
        }
        #puts "#{q.css('symbol').text}: #{q.css('last').text}"
      end


      #prices = Array.new
      #while rd.read(2).bytes != [255,255]   # The terminator char is "\xFF\xFF"
        #rd.seek(-2, IO::SEEK_CUR)
        #quote = QuoteResult.read(rd)
        #quotes << {
        #    result: quote.result,
        #
        #
        #    open: bar.open.round(2),
        #    high: bar.high.round(2),
        #    low: bar.low.round(2),
        #    close: bar.close.round(2),
        #    volume: bar.volume,
        #    timestamp: Time.at(bar.timestampint/1000),
        #    interval: :minute
        #}
        #puts "#{bar.open} #{bar.high} #{bar.low} #{bar.close} #{Time.at(bar.timestampint/1000)}"
      #end

      quotes
    end

  private
    def todays_date
      Date.today
    end

    def parse_last_trade_date(date_string)
      DateTime.parse(date_string)
    rescue
      0
    end

    def date_s(date)
      date.strftime('%Y%m%d')
    end

    def validate_price_history_options(options)
      if options.has_key?(:intervaltype) && INTERVAL_TYPE.index(options[:intervaltype]).nil?
        raise TDAmeritradeApiError, "Invalid price history option for intervaltype: #{options[:intervaltype]}"
      end

      if options.has_key?(:periodtype) && PERIOD_TYPE.index(options[:periodtype]).nil?
        raise TDAmeritradeApiError, "Invalid price history option for periodtype: #{options[:periodtype]}"
      end

    end

    def build_price_history_request_params(symbol, options)
      req = {source: @source_id, requestidentifiertype: 'SYMBOL', requestvalue: symbol}.merge(options)
      req[:startdate]=date_s(req[:startdate]) if req.has_key?(:startdate) && req[:startdate].is_a?(Date)
      req[:enddate]=date_s(req[:enddate]) if req.has_key?(:enddate) && req[:enddate].is_a?(Date)
      req[:intervaltype]=req[:intervaltype].to_s.upcase if req[:intervaltype]
      req[:periodtype]=req[:periodtype].to_s.upcase
      req
    end


  end
end