require 'net/http'
require 'tdameritrade_api/bindata_types'

module TDAmeritradeApi
  module Streamer

    # +create_streamer+ use this to create a connection to the TDA streaming server
    def create_streamer
      Streamer.new(get_streamer_info, login_params_hash, @session_id)
    end

    class Streamer
      STREAMER_REQUEST_URL='http://ameritrade02.streamer.com/'

      attr_reader :streamer_info_response, :authentication_params, :session_id

      def initialize(streamer_info_raw, login_params, session_id)
        @streamer_info_response = streamer_info_raw

        @authentication_params = Hash.new
        @authentication_params = @authentication_params.merge(login_params).merge(parse_streamer_info)

        @session_id = session_id
      end

      def run(&block)
        uri = URI.parse STREAMER_REQUEST_URL
        post_data="!U=#{authentication_params[:account_id]}&W=#{authentication_params[:token]}&" +
            "A=userid=#{authentication_params[:account_id]}&token=#{authentication_params[:token]}&" +
            "company=#{authentication_params[:company]}&segment=#{authentication_params[:segment]}&" +
            "cddomain=#{authentication_params[:cd_domain_id]}&usergroup=#{authentication_params[:usergroup]}&" +
            "accesslevel=#{authentication_params[:access_level]}&authorized=#{authentication_params[:authorized]}&" +
            "acl=#{authentication_params[:acl]}&timestamp=#{authentication_params[:timestamp]}&" +
            "appid=#{authentication_params[:app_id]}|S=QUOTE&C=SUBS&P=VXX+XIV&T=0+1+2|control=false" +
            "|source=#{authentication_params[:source]}\n\n"

        request = Net::HTTP::Post.new('/')
        request.body = post_data

        Net::HTTP.start(uri.host, uri.port) do |http|
          http.request(request) do |res|
            res.read_body do |chunk|
              puts chunk # this is just for testing/setup
            end
          end
        end

        # thread = Thread.new do
        #   # 25.times do |i|
        #   #   yield({the_data: 123, iteration: i})
        #   #   sleep 1
        #   #end
        # end
      end

      private

      def build_parameters(opts={})
        {
            "!U"=>authentication_params[:account_id],
            "W"=>authentication_params[:token],
            "A=userid"=>authentication_params[:account_id],
            "token"=>authentication_params[:token],
            "company"=>authentication_params[:company],
            "segment"=>authentication_params[:segment],
            "cddomain"=>authentication_params[:cd_domain_id],
            "usergroup"=>authentication_params[:usergroup],
            "accesslevel"=>authentication_params[:access_level],
            "authorized"=>authentication_params[:authorized],
            "acl"=>authentication_params[:acl],
            "timestamp"=>authentication_params[:timestamp],
            "appid"=>authentication_params[:app_id],
            "source"=>authentication_params[:source],
            "version"=>"1.0"
        }.merge(opts)
      end

      def parse_streamer_info
        p = Hash.new
        r = Nokogiri::XML::Document.parse @streamer_info_response
        si = r.xpath('/amtd/streamer-info').first
        p[:token] = si.xpath('token').text
        p[:cd_domain_id] = si.xpath('cd-domain-id').text
        p[:usergroup] = si.xpath('usergroup').text
        p[:access_level] = si.xpath('access-level').text
        p[:acl] = si.xpath('acl').text
        p[:app_id] = si.xpath('app-id').text
        p[:authorized] = si.xpath('authorized').text
        p[:timestamp] = si.xpath('timestamp').text
        p
      end
    end

    private

    STREAMER_INFO_URL='https://apis.tdameritrade.com/apps/100/StreamerInfo'

    def get_streamer_info
      uri = URI.parse STREAMER_INFO_URL
      uri.query = URI.encode_www_form({source: @source_id})

      response = HTTParty.get(uri, headers: {'Cookie' => "JSESSIONID=#{@session_id}"}, timeout: 10)
      if response.code != 200
        raise TDAmeritradeApiError, "HTTP response #{response.code}: #{response.body}"
      end

      response.body
    end

    def login_params_hash
      {
          company: @accounts.first[:company],
          segment: @accounts.first[:segment],
          account_id: @accounts.first[:account_id],
          source: @source_id
      }
    end
  end
end