require 'net/http'
require 'openssl'
require 'tmpdir'
require 'bindata'

module TDAmeritradeApi
  class PriceHistoryHeader < BinData::Record
    int32be    :symbol_count
    int16be    :symbol_length
    string     :symbol, :read_length=>:symbol_length
    int8be     :error_code
    int16be    :error_length, :onlyif => :has_error?
    string     :error_text, :onlyif => :has_error?, :length=>:error_length
    int32be    :bar_count

    def has_error?
      error_code != 0
    end
  end

  class PriceHistoryBarRaw < BinData::Record
    float_be    :close   # may have to round this on a 64 bit system
    float_be    :high    # may have to round this on a 64 bit system
    float_be    :low     # may have to round this on a 64 bit system
    float_be    :open    # may have to round this on a 64 bit system
    float_be    :volume  # in 100s
    int64be     :timestampint # number of milliseconds - needs to be converted to seconds for Ruby
  end


  class Client
    attr_accessor :session_id, :source_id, :user_id, :password

    def initialize
      self.source_id=ENV['TDAMERITRADE_SOURCE_KEY']
      self.user_id=ENV['TDAMERITRADE_USER_ID']
      self.password=ENV['TDAMERITRADE_PASSWORD']
    end

    def login
      uri = URI.parse("https://apis.tdameritrade.com/apps/100/LogIn?source=#{@source_id}&version=1.0.0")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      #http.verify_mode = OpenSSL::SSL::VERIFY_NONE  # this was in a code sample. do I really need this line?
      request = Net::HTTP::Post.new(uri.path)
      request.add_field('Content-Type', 'application/x-www-form-urlencoded')
      request.body = "userid=#{@user_id}&password=#{@password}&source=#{@source_id}&version=1.0.0"
      result = http.request(request)
      puts result
      puts result.body

      login_result = result.body.scan(/<result>(.*)<\/result>/).first.first
      login_result = login_result == "OK" ? true : false
      if login_result
        self.session_id=result.body.scan(/<session-id>(.*)<\/session-id>/).first.first
      end

      login_result
    end

    def get_daily_price_history(symbol, begin_date="20010102", end_date=todays_date)
      begin
        uri = URI.parse("https://apis.tdameritrade.com/apps/100/PriceHistory?source=#{@source_id}&requestidentifiertype=SYMBOL&requestvalue=#{symbol}&intervaltype=DAILY&intervalduration=1&startdate=#{begin_date}&enddate=#{end_date}")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.read_timeout = 10
        request = Net::HTTP::Get.new uri
        request['Set-Cookie'] = "JSESSIONID=#{@session_id}"
        puts "sending request, #{http.read_timeout}"
        response = http.request request
        puts response
        puts "request received"
      rescue
        puts 'error downloading in get_daily_price_history'
      end

      if response.code != "200"
        return [{ :error => "#{response.code}: #{response.body.encode('utf-8')}"}]
      end


      tmp_file=File.join(Dir.tmpdir, "daily_prices.binary")
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
            volume: bar.volume.round(2),
            timestamp: Time.at(bar.timestampint/1000),
            interval: :day
        }
        #puts "#{bar.open} #{bar.high} #{bar.low} #{bar.close} #{Time.at(bar.timestampint/1000)}"
      end

      prices
    end

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
      Date.today.strftime('%Y%m%d')
    end

    def parse_last_trade_date(date_string)
      DateTime.parse(date_string)
    rescue
      0
    end

  end
end