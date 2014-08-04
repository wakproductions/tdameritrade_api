require 'spec_helper'

describe TDAmeritradeApi::Client do
  let(:client) { RSpec.configuration.client }
  let(:streamer) {client.create_streamer}

  # Settings for manually running individual tests
  let(:mock_data_file) { File.join(Dir.pwd, 'spec', 'test_data', 'sample_stream_20140804.binary') }
  let(:display_output) { true }
  let(:use_mock_data_file) { true }
  let(:connect_to_stream) { false }

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
        case data.stream_data_type
          when :heartbeat
            pout "Heartbeat: #{data.timestamp}"
          when :snapshot
            if data.service_id == "100"
              pout "Snapshot SID-#{data.service_id}: #{data.message}"
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

      request_fields = [:volume, :last, :bid, :symbol, :ask, :quotetime, :high, :low, :close, :tradetime, :tick]
      symbols = ['VXX','XIV','UVXY','FEYE','KNDI','LOCO','GLUU','DD','UAL']

      streamer.output_file = File.join(Dir.pwd, 'spec', 'test_data', 'sample_stream_20140804.binary') if use_mock_data_file
      streamer.run(symbols: symbols, request_fields: request_fields) do |data|
        data.convert_time_columns
        case data.stream_data_type
          when :heartbeat
            pout "Heartbeat: #{data.timestamp}"
          when :snapshot
            if data.service_id == "100"
              pout "Snapshot SID-#{data.service_id}: #{data.message}"
            else
              pout "Snapshot: #{data}"
            end
          when :stream_data
            pout "Stream: #{data.columns}"
          else
            pout "Unknown type of data: #{data}"
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
end