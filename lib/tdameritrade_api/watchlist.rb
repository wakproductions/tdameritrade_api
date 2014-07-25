require 'httparty'
require 'tdameritrade_api/exception'

module TDAmeritradeApi
  module Watchlist
    GET_WATCHLISTS_URL='https://apis.tdameritrade.com/apps/100/GetWatchlists'

    def get_watchlists(opts={})
      request_params = { source: @source_id }
      request_params.merge(opts)  # valid values are accountid and listid - see the API docs for details

      uri = URI.parse GET_WATCHLISTS_URL
      uri.query = URI.encode_www_form(request_params)
      #puts uri

      response = HTTParty.get(uri, headers: {'Set-Cookie' => "JSESSIONID=#{@session_id}"}, timeout: 10)
      if response.code != 200
        raise TDAmeritradeApiError, "HTTP response #{response.code}: #{response.body}"
      end

      puts response.body

    rescue Exception => e
      raise TDAmeritradeApiError, "error retrieving watchlists - #{e.message}" if !e.is_ctrl_c_exception?
    end

  end
end