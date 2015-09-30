module TDAmeritradeApi
  module BalancesAndPositions
    BP_URL='https://apis.tdameritrade.com/apps/100/BalancesAndPositions'
    
    # +get_balances_and_positions+ get account balances
    # +options+ may contain any of the params outlined in the API docs
    def get_balances_and_positions(options)
      request_params = build_bp_params(options)

      uri = URI.parse BP_URL
      uri.query = URI.encode_www_form(request_params)

      response = HTTParty.get(uri, headers: {'Cookie' => "JSESSIONID=#{@session_id}"}, timeout: 10)
      if response.code != 200
        raise TDAmeritradeApiError, "HTTP response #{response.code}: #{response.body}"
      end

      bp_hash = {"error"=>"failed"}      
      result_hash = Hash.from_xml(response.body.to_s)
      if result_hash['amtd']['result'] == 'OK' then
        bp_hash = result_hash['amtd']['positions']
      end

      bp_hash
    rescue Exception => e
      raise TDAmeritradeApiError, "error in get_balances_and_positions() - #{e.message}" if !e.is_ctrl_c_exception?
    end

    private

    def build_bp_params(options)
      req = {source: @source_id, accountid: @accounts[0][:account_id]}.merge(options)
    end
  end
end