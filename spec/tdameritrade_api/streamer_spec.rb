require 'spec_helper'

describe TDAmeritradeApi::Client do
  let(:client) { RSpec.configuration.client }
  let(:streamer) {client.create_streamer}

  # Settings for manually running individual tests
  let(:mock_data_file) { File.join(Dir.pwd, 'spec', 'test_data', 'sample_stream_archives', 'sample_stream_20140804.binary') }
  #let(:watchlist) { ['VXX','XIV','UVXY','DD','UAL','PG','MSFT'] }
  let(:watchlist) { load_watchlist }
  let(:display_output) { true }
  let(:use_mock_data_file) { true }
  let(:connect_to_stream) { true }

  it 'should create a valid streamer' do
    expect(streamer.streamer_info_response).to be_a(String)
    expect(streamer.authentication_params).to be_a(Hash)
  end

  # This test is to provide a controlled input for testing against the stream processing routines.
  # It is more useful than connecting to the stream directly because you may not have much data coming in
  # depending on whether the market is open when you run the test against a live connection.
  it 'should be able to process a complex stream saved to a file' do
    if use_mock_data_file && !connect_to_stream
      pout "Testing Level 1 stream from mock data"

      streamer = TDAmeritradeApi::Streamer::Streamer.new(read_from_file: mock_data_file)
      streamer.run do |data|
        data.convert_time_columns
        case data.stream_data_type
          when :heartbeat
            pout "Heartbeat: #{data.timestamp}"
          when :snapshot
            if data.service_id == "100"
              pout "Snapshot SID-#{data.service_id}: #{data.columns[:description]}"
            else
              pout "Snapshot: #{data}"
            end
          when :stream_data
            cols = data.columns.each { |k,v| "#{k}: #{v}   "}
            pout "Stream: #{cols}"
          else
            pout "Unknown type of data: #{data}"
        end
      end
    else
      expect(true).to be_true
    end

  end


  # !!! THIS TEST IS NOT COMPLETE WITH EXPECTATIONS YET !!!
  it "should be able to download and process streaming data from TDA" do
    if connect_to_stream
      pout "Testing TD Ameritrade Level 1 quote data stream"

      i = 0
      file_num = 1
      request_fields = [:volume, :last, :bid, :symbol, :ask, :quotetime, :high, :low, :close, :tradetime, :tick]
      symbols = watchlist

      while true
        begin
          file_num += 1 while File.exists? File.join(Dir.pwd, 'spec', 'test_data', 'sample_stream_archives', new_mock_data_file_name(file_num))
          streamer.output_file = File.join(Dir.pwd, 'spec', 'test_data', 'sample_stream_archives', new_mock_data_file_name(file_num)) if use_mock_data_file
          streamer.run(symbols: symbols, request_fields: request_fields) do |data|
            data.convert_time_columns
            case data.stream_data_type
              when :heartbeat
                pout "Heartbeat: #{data.timestamp}"
              when :snapshot
                if data.service_id == "100"
                  pout "Snapshot SID-#{data.service_id}: #{data.columns[:description]}"
                else
                  pout "Snapshot: #{data}"
                end
              when :stream_data
                pout "#{i} Stream: #{data.columns}"
                i += 1
              else
                pout "Unknown type of data: #{data}"
            end
          end
        rescue Exception => e
          # This idiom of a rescue block you can use to reset the connection if it drops,
          # which can happen easily during a fast market.
          if e.class == Errno::ECONNRESET
            puts "Connection reset, reconnecting..."
          else
            raise e
          end
        end
      end
    else
      expect(true).to be_true
    end


  end

private
  def pout(output)
    puts output if display_output
  end

  def load_watchlist
    wl_file = File.join(Dir.pwd, 'spec', 'test_data', 'watchlist.txt')
    f = File.open(wl_file, 'r')
    list = f.read().split("\n")
    f.close
    list
  end

  def new_mock_data_file_name(i)
    "sample_stream_#{Date.today.strftime('%Y%m%d')}-0#{i}.binary"
  end
end