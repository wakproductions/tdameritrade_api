require 'httparty'
require 'nokogiri'
require 'tdameritrade_api/constants'
require 'tdameritrade_api/tdameritrade_api_error'

module TDAmeritradeApi
  module Watchlist
    include Constants
    GET_WATCHLISTS_URL   = 'https://apis.tdameritrade.com/apps/100/GetWatchlists'
    CREATE_WATCHLIST_URL = 'https://apis.tdameritrade.com/apps/100/CreateWatchlist'
    EDIT_WATCHLIST_URL = 'https://apis.tdameritrade.com/apps/100/EditWatchlist'

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

      response = HTTParty.get(uri, headers: {'Cookie' => "JSESSIONID=#{@session_id}"}, timeout: DEFAULT_TIMEOUT)
      if response.code != 200
        fail "HTTP response #{response.code}: #{response.body}"
      end

      watchlists = Array.new
      w = Nokogiri::XML::Document.parse response.body
      w.css('watchlist').each do |watchlist|
        watchlist_name = watchlist.css('name').text
        watchlist_id = watchlist.css('id').text
        watchlist_symbols = []

        watchlist.css('watched-symbol').each do |ws|
          watchlist_symbols << ws.css('security symbol').text
        end

        watchlists << { name: watchlist_name, id: watchlist_id, symbols: watchlist_symbols }
      end

      watchlists

    rescue Exception => e
      raise TDAmeritradeApiError, "error retrieving watchlists - #{e.message}" if !e.is_ctrl_c_exception?
    end

    def create_watchlist(opts={})
      # valid values are watchlistname and symbollist - see the API docs for details
      fail 'watchlistname required!' unless opts[:watchlistname]
      fail 'symbollist required! (at least 1 symbol)' unless opts[:symbollist]
      opts[:symbollist] = opts[:symbollist].join(',') if opts[:symbollist].is_a? Array
      #request_params = { source: @source_id }.merge(opts) #TODO write a method to build params using this

      uri = URI.encode(
        CREATE_WATCHLIST_URL << "?source=#{@source_id}&watchlistname=#{opts[:watchlistname]}&symbollist=#{opts[:symbollist]}"
      )

      response = HTTParty.get(uri, headers: {'Cookie' => "JSESSIONID=#{@session_id}"}, timeout: DEFAULT_TIMEOUT)
      if response.code != 200
        fail "HTTP response #{response.code}: #{response.body}"
      end

      w = Nokogiri::XML::Document.parse response.body
      result = {
        result:      w.css('result').text,
        error:       w.css('error').text,
        account_id:  w.css('account-id').text,
        watchlistname: w.css('created-watchlist name').text
      }
      watchlist = []
      w.css('created-watchlist symbol-list watched-symbol').each do |ws|
        watchlist << {
          symbol:                    ws.css('symbol').text,
          symbol_with_type_prefix:   ws.css('symbol-with-type-prefix').text,
          description:               ws.css('description').text,
          asset_type:                ws.css('asset-type').text
        }
      end
      result[:watchlist] = watchlist
      result
    rescue Exception => e
      raise TDAmeritradeApiError, e.message
    end

    def edit_watchlist(opts={})
      # valid values are watchlistname and symbollist - see the API docs for details
      fail 'listid required!' unless opts[:listid]
      fail 'symbollist required! (at least 1 symbol)' unless opts[:symbollist]
      opts[:symbollist] = opts[:symbollist].join(',') if opts[:symbollist].is_a? Array
      #request_params = { source: @source_id }.merge(opts) #TODO write a method to build params using this

      uri = URI.encode(
        EDIT_WATCHLIST_URL << "?source=#{@source_id}&listid=#{opts[:listid]}&symbollist=#{opts[:symbollist]}"
      )

      response = HTTParty.get(uri, headers: {'Cookie' => "JSESSIONID=#{@session_id}"}, timeout: DEFAULT_TIMEOUT)
      if response.code != 200
        fail "HTTP response #{response.code}: #{response.body}"
      end

      w = Nokogiri::XML::Document.parse response.body
      result = {
        result:      w.css('result').text,
        error:       w.css('edit-watchlist-result error').text,
        account_id:  w.css('edit-watchlist-result account-id').text,
        watchlistname: w.css('edited-watchlist name').text
      }
      watchlist = []
      w.css('edited-watchlist symbol-list watched-symbol').each do |ws|
        watchlist << {
          symbol:                    ws.css('symbol').text,
          symbol_with_type_prefix:   ws.css('symbol-with-type-prefix').text,
          description:               ws.css('description').text,
          asset_type:                ws.css('asset-type').text
        }
      end
      result[:watchlist] = watchlist
      result
    rescue Exception => e
      raise TDAmeritradeApiError, e.message
    end
  end
end