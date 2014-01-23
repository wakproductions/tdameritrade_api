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
      self.source_id =ENV['TDAMERITRADE_SOURCE_KEY']
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

    def get_daily_price_history(symbol, begin_date="20130101", end_date="20140121")
      uri = URI.parse("https://apis.tdameritrade.com/apps/100/PriceHistory?source=#{@source_id}&requestidentifiertype=SYMBOL&requestvalue=#{symbol}&intervaltype=DAILY&intervalduration=1&startdate=#{begin_date}&enddate=#{end_date}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new uri
      request['Set-Cookie'] = "JSESSIONID=#{@session_id}"
      response = http.request request

      tmp_file=File.join(Dir.tmpdir, "#{symbol}_daily_prices.binary")
      download_file = open(tmp_file, 'wb')
      download_file.write(response.body)
      download_file.close
      rd = open(tmp_file, 'rb')

      header = PriceHistoryHeader.read(rd)
      puts "#{header.symbol}: #{header.bar_count} bars"

      if header.error_code != 0
        raise "#{header.error_code} - #{header.error_text}"
      end

      prices = Array.new
      while rd.read(2).bytes != [255,255]   # The terminator char is "\xFF\xFF"
        rd.seek(-2, IO::SEEK_CUR)
        bar = PriceHistoryBarRaw.read(rd)
        prices << {
            open: bar.open,
            high: bar.high,
            low: bar.low,
            close: bar.close,
            volume: bar.volume,
            timestamp: Time.at(bar.timestampint/1000),
            interval: :day
        }
        puts "#{bar.open} #{bar.high} #{bar.low} #{bar.close} #{Time.at(bar.timestampint/1000)}"
      end

      prices
    end

    def get_minute_price_history(symbol, days_back=1)
      # for it to get today's data, you have to set the enddate parameter to today
      # See forum post #10597
      uri = URI.parse("https://apis.tdameritrade.com/apps/100/PriceHistory?source=WIKO&requestidentifiertype=SYMBOL&requestvalue=#{symbol}&intervaltype=MINUTE&intervalduration=1&periodtype=DAY&period=#{days_back}&extended=true&enddate=20140121")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new uri
      request['Set-Cookie'] = "JSESSIONID=#{@session_id}"
      response = http.request request

      tmp_file=File.join(Dir.tmpdir, "#{symbol}_minute_prices.binary")
      download_file = open(tmp_file, 'wb')
      download_file.write(response.body)
      download_file.close
      rd = open(tmp_file, 'rb')

      header = PriceHistoryHeader.read(rd)
      puts "#{header.symbol}: #{header.bar_count} bars"

      if header.error_code != 0
        raise "#{header.error_code} - #{header.error_text}"
      end

      prices = Array.new
      while rd.read(2).bytes != [255,255]   # The terminator char is "\xFF\xFF"
        rd.seek(-2, IO::SEEK_CUR)
        bar = PriceHistoryBarRaw.read(rd)
        prices << {
            open: bar.open,
            high: bar.high,
            low: bar.low,
            close: bar.close,
            volume: bar.volume,
            timestamp: Time.at(bar.timestampint/1000),
            interval: :minute
        }
        #puts "#{bar.open} #{bar.high} #{bar.low} #{bar.close} #{Time.at(bar.timestampint/1000)}"
      end

      prices
    end

  end
end