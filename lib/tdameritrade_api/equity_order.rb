module TDAmeritradeApi
  module EquityOrder
    EQUITYORDER_URL='https://apis.tdameritrade.com/apps/100/EquityTrade'
    
    ACTION_TYPE=[:sell, :buy, :sellshort, :buytocover]
    EXPIRE_TYPE=[:day, :moc, :day_ext, :gtc, :gtc_ext, :am, :pm]
    ORDER_TYPE=[:market, :limit, :stop_market, :stop_limit, :tstoppercent, :tstopdollar]
    ROUTING_TYPE=[:auto, :inet, :ecn_arca]
    SPINSTRUCTIONS_TYPE=[:none, :fok, :aon, :dnr, :aon_dnr]

    # for conditional orders    
    CONDITIONALORDER_URL='https://apis.tdameritrade.com/apps/100/ConditionalEquityTrade'
    ORDER_TICKET=[:oca, :ota, :ott, :otoca, :otota]

    # +submit_order+ submit equity order
    # +options+ may contain any of the params outlined in the API docs
    def submit_order(symbol, order_info, conditional=false)
      validate_order_options(order_info, conditional)
      request_params = build_order_request_params(symbol, order_info)

      if !conditional then
        uri = URI.parse EQUITYORDER_URL
      else
        uri = URI.parse CONDITIONALORDER_URL
      end
      
      uri.query = URI.encode_www_form(request_params)

      response = HTTParty.get(uri, headers: {'Cookie' => "JSESSIONID=#{@session_id}"}, timeout: 10)
      if response.code != 200
        raise TDAmeritradeApiError, "HTTP response #{response.code}: #{response.body}"
      end

    parsed_response = Nokogiri::XML::Document.parse response.body
    
    p response.body

    rescue Exception => e
      raise TDAmeritradeApiError, "error in submit_order() - #{e.message}" if !e.is_ctrl_c_exception?
    end
    
    def edit_order(order_options)
    end

    def cancel_order(order_options)
    end
    
    def get_order_status(order_options)
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

    def validate_order_options(options, conditional)
      if (conditional && !(options.has_key?(:totlegs) && 1 < options[:totlegs] < 4))
        raise TDAmeritradeApiError, "For conditional orders totlegs must be 2 or 3: #{options[:totlegs]}"
      end
      
      (0..3).each do |leg|
          next if conditional && leg == 0
          next if !conditional && leg > 0
          subscript = leg == 0 ? "" : leg
          
          if !(options.has_key?(:"quantity#{subscript}") && options[:"quantity#{subscript}"].is_a?(Integer))
            raise TDAmeritradeApiError, "You must provide a quantity#{subscript}: #{options[:"quantity#{subscript}"]}"
          end
    
          if options.has_key?(:clientorderid) && !options[:clientorderid].is_a?(Integer)
            raise TDAmeritradeApiError, "Option clientorderid must be Integer: #{options[:clientorderid]}"
          end
    
          ## TODO Add more:
          
          if !options.has_key?(:"action#{subscript}") || ACTION_TYPE.index(options[:"action#{subscript}"]).nil?
            raise TDAmeritradeApiError, "Invalid equity trade option for action#{subscript}: #{options[:"action#{subscript}"]}"
          end
       end

    end

    def build_order_request_params(symbol, options)
      req = {source: @source_id}.merge(options)
      
      req[:accountid] = @accounts[0][:account_id]

      req[:symbol] = symbol.to_s.upcase

      req
    end
  end
end