require 'net/http'
require 'tdameritrade_api/streamer_types'

module TDAmeritradeApi
  module Streamer

    # +create_streamer+ use this to create a connection to the TDA streaming server
    def create_streamer
      Streamer.new(streamer_info_raw: get_streamer_info, login_params: login_params_hash, session_id: @session_id)
    end

    class Streamer
      include StreamerTypes
      STREAMER_REQUEST_URL='http://ameritrade02.streamer.com/'

      attr_reader :streamer_info_response, :authentication_params, :session_id, :thread

      def initialize(opt={})
        if opt.has_key? :read_from_file
          @read_from_file = opt[:read_from_file] # if this option is used, it will read the stream from a saved file instead of connecting
        else
          @streamer_info_response = opt[:streamer_info_raw]
          @session_id = opt[:session_id]

          @authentication_params = Hash.new
          @authentication_params = @authentication_params.merge(opt[:login_params]).merge(parse_streamer_request_params)
        end

        @buffer = String.new
        @message_block = nil
      end

      def run(&block)
        @message_block = block

        if !@read_from_file.nil?
          run_from_file
          return
        end

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

        #outfile=File.join(Dir.tmpdir, "sample_stream.binary")
        #w = open(outfile, 'wb')
        Net::HTTP.start(uri.host, uri.port) do |http|
          http.request(request) do |response|
            response.read_body do |chunk|
              @buffer = @buffer + chunk
              #w.write(chunk)
              process_buffer
            end
          end
        end
        # @thread = Thread.new do
        #   # 25.times do |i|
        #   #   yield({the_data: 123, iteration: i})
        #   #   sleep 1
        #   #end
        # end
      end

      private

      def post_data(data)
        @message_block.call(data) # sends formatted stream data back to wherever Streamer.run was called
      end

      def run_from_file
        r = open(@read_from_file, 'rb')
        while data=r.read(100)
          @buffer = @buffer + data
          process_buffer
        end
      end

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

      def parse_streamer_request_params
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

      def next_record_type_in_buffer
        if @buffer.length > 0
          case @buffer[0]
            when 'H'
              return :heartbeat
            when 'N'
              return :snapshot
            when 'S'
              return :stream_data
            else
              return nil
          end
        else
          return nil
        end
      end

      def unload_buffer(bytes)
        @buffer.slice!(0,bytes)
      end

      def process_heartbeat
        return false if @buffer.length < 2

        if @buffer[0] == 'H'
          hb = StreamData.new(:heartbeat)

          # Next char is 'T' (followed by time stamp) or 'H' (no time stamp)
          if @buffer[1] == 'T'
            return false if @buffer.length < 10
            hb.timestamp_indicator = true
            hb.timestamp = Time.at(@buffer[2..9].reverse.unpack('q').first/1000)
            unload_buffer(10)
          elsif @buffer[1] != 'H'
            hb.timestamp_indicator = false
            unload_buffer(2)
          else
            raise TDAmeritradeApiError, "Unexpected character in stream. Expected: Heartbeat timestamp indicator 'T' or 'H'"
          end

          post_data(hb)
          true
        end

      end

      def process_snapshot
        return false if @buffer.bytes.each_cons(2).to_a.index([0xFF,0x0A]).nil?

        n = StreamData.new(:snapshot)
        data = @buffer.slice!(0, @buffer.bytes.each_cons(2).to_a.index([0xFF,0x0A]) + 2)
        service_id_length = data[1..2].reverse.unpack('S').first
        n.service_id = data.slice(3, service_id_length)
        data.slice!(0, 3 + service_id_length)

        case n.service_id
          when "1" # level 1 quote
            # TODO Need to support this kind of snapshot
            n.message = "'N' Snapshot found (level 1 quote, unsupported type): #{n.service_id}"
          when "100"  # message from the server
            # next field will be the message length (4 bytes) followed by the message
            message_length = data[0..3].reverse.unpack('S').first
            n.message = data.slice(4, message_length)
          else
            n.message = "'N' Snapshot found (unsupported type): #{n.service_id}"
        end
        post_data(n)
        true
      end

      def process_stream_record
        return false if @buffer.bytes.each_cons(2).to_a.index([0xFF,0x0A]).nil?

        # !!!! THIS IS TEMPORARY PSEUDOCODE THAT DOES NOT REALLY PROCESS !!!!
        data = @buffer.slice!(0, @buffer.bytes.each_cons(2).to_a.index([0xFF,0x0A]) + 2)
        s = StreamData.new(:stream_data)
        s.message = "'S' Stream data found: #{data}"
        post_data(s)
        true
      end

      def process_buffer
        # advance until we get a recognizable code in the stream
        until @buffer.length == 0 || !next_record_type_in_buffer.nil?
          @buffer.slice!(0,1)
        end

        process_next = true
        until (process_next == false) || (next_record_type_in_buffer.nil?)
          case next_record_type_in_buffer
            when :heartbeat
              process_next = process_heartbeat
            when :snapshot
              process_next = process_snapshot
            when :stream_data
              process_next = process_stream_record
          end
        end
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