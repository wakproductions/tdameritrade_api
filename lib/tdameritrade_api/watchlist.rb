require 'httparty'
require 'nokogiri'
require 'tdameritrade_api/exception'

module TDAmeritradeApi
  module Watchlist
    GET_WATCHLISTS_URL='https://apis.tdameritrade.com/apps/100/GetWatchlists'

    # +get_watchlists+ allows you to retrieve watchlists for the associated account. Valid values for
    # opts are :accountid and :listid. See API docs for details. Returns an array of hashes, each
    # hash containing the :watchlist_name, and array of :ticker_symbols followed on the watchlist.
    # Note that as of now the data returned is not exactly in the same organization or level of detail
    # as the data returned by the TDA API.
    def get_watchlists(opts={})
      request_params = { source: @source_id }
      request_params.merge(opts)  # valid values are accountid and listid - see the API docs for details

      uri = URI.parse GET_WATCHLISTS_URL
      uri.query = URI.encode_www_form(request_params)

      response = HTTParty.get(uri, headers: {'Cookie' => "JSESSIONID=#{@session_id}"}, timeout: 10)
      if response.code != 200
        raise TDAmeritradeApiError, "HTTP response #{response.code}: #{response.body}"
      end

      watchlists = Array.new
      w = Nokogiri::XML::Document.parse response.body
      w.css('watchlist').each do |watchlist|
        watchlist_name = watchlist.css('name').text
        watchlist_id = watchlist.css('id').text
        watchlist_symbols = Array.new

        watchlist.css('watched-symbol').each do |ws|
          watchlist_symbols << ws.css('security symbol').text
        end

        watchlists << { name: watchlist_name, id: watchlist_id, symbols: watchlist_symbols }
      end

      watchlists

    rescue Exception => e
      raise TDAmeritradeApiError, "error retrieving watchlists - #{e.message}" if !e.is_ctrl_c_exception?
    end

  end
end