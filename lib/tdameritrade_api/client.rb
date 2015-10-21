require 'net/http'
require 'openssl'
require 'httparty'
require 'active_support/core_ext/hash/conversions'
require 'tdameritrade_api/bindata_types'
require 'tdameritrade_api/exception'
require 'tdameritrade_api/price_history'
require 'tdameritrade_api/streamer'
require 'tdameritrade_api/watchlist'
require 'tdameritrade_api/balances_and_positions'

module TDAmeritradeApi
  class Client
    include PriceHistory
    include Streamer
    include Watchlist
    include BalancesAndPositions

    attr_accessor :source_id, :user_id, :password
    attr_reader :login_response, :session_id, :accounts

    def initialize
      self.source_id=ENV['TDAMERITRADE_SOURCE_KEY']
      self.user_id=ENV['TDAMERITRADE_USER_ID']
      self.password=ENV['TDAMERITRADE_PASSWORD']
    end

    def login
      clear_login_data
      uri = URI.parse("https://apis.tdameritrade.com/apps/100/LogIn?source=#{@source_id}&version=1.0.0")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(uri.path)
      request.add_field('Content-Type', 'application/x-www-form-urlencoded')
      request.body = "userid=#{@user_id}&password=#{@password}&source=#{@source_id}&version=1.0.0"
      result = http.request(request)
      @login_response = result.body

      parse_login_response if login_success?
      login_success?
    end

    def login_success?
      return false if @login_response.nil?
      begin
        login_result = @login_response.scan(/<result>(.*)<\/result>/).first.first
      rescue
        return false
      end
      login_result && (login_result == "OK")
    end

    private

    def parse_login_response
      @session_id = @login_response.scan(/<session-id>(.*)<\/session-id>/).first.first
      @accounts = Array.new
      r = Nokogiri::XML::Document.parse @login_response
      r.xpath('/amtd/xml-log-in/accounts/account').each do |account|
        a = Hash.new
        a[:account_id] = account.xpath('account-id').text
        a[:display_name] = account.xpath('display-name').text
        a[:description] = account.xpath('description').text
        a[:company] = account.xpath('company').text
        a[:segment] = account.xpath('segment').text
        @accounts << a
      end
    end

    def clear_login_data
      @login_response = nil
      @session_id = nil
      @accounts = nil
    end

  end
end