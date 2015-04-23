require 'spec_helper'

describe TDAmeritradeApi::Client do
  let(:client) { RSpec.configuration.client }
  let(:streamer) {client.create_streamer}
  let(:watchlist) { load_watchlist }
  let(:mock_data_file) { File.join(Dir.pwd, 'spec', 'test_data', 'sample_stream_20140807.binary') }

  # These three below are settings you can change for working on the tests and experimenting with the gem
  let(:display_output) { false }
  let(:test_mock_data) { true }
  let(:connect_to_stream) { true }

  it 'should create a valid streamer' do
    expect(streamer.streamer_info_response).to be_a(String)
    expect(streamer.authentication_params).to be_a(Hash)
  end

  # This is intended to test the quote processing system by reading a previously saved stream of data.
  # It is more useful than connecting to the stream directly because you may not have much data coming in
  # depending on whether the market is open when you run the test against a live connection.
  #
  # You can turn off this test by setting the test_mock_data variable to false
  it 'should be able to process a complex stream saved to a file' do
    if test_mock_data
      #display_output_before = display_output
      pout "Testing Level 1 stream from mock data"
      first_heartbeat = nil
      first_stream_data = nil

      i = 1
      streamer = TDAmeritradeApi::Streamer::Streamer.new(read_from_file: mock_data_file)
      streamer.run do |data|
        data.convert_time_columns Date.new(2014,07,16) # Date that /spec/test_data/sample_stream_rspec_test.binary was created. Must update this date if you change the sample file bc of daylight savings time adjustment.
        case data.stream_data_type
          when :heartbeat
            pout "Heartbeat: #{data.timestamp}"
            first_heartbeat = data if first_heartbeat.nil?
          when :snapshot
            if data.service_id == "100"
              pout "Snapshot SID-#{data.service_id}: #{data.columns[:description]}"
            else
              pout "Snapshot: #{data}"
            end
          when :stream_data
            first_stream_data = data if first_stream_data.nil?
            cols = data.columns.each { |k,v| "#{k}: #{v}   "}
            pout "Stream: #{cols}"
          else
            pout "Unknown type of data: #{data}"
        end
        i += 1
        streamer.quit if i == 15
      end
    end
    expect(first_heartbeat.timestamp).to eql(Time.parse("2014-07-16 09:49:34 -0400"))
    expect(first_stream_data.columns[:symbol]).to eql("ETN")
    expect(first_stream_data.columns[:bid]).to eql(47.76)
    expect(first_stream_data.columns[:ask]).to eql(47.78)
    expect(first_stream_data.columns[:last]).to eql(47.86)
    expect(first_stream_data.columns[:volume]).to eql(3424063)
    expect(first_stream_data.columns[:tradetime]).to eql(69439)
    expect(first_stream_data.columns[:quotetime]).to eql(72000)
    expect(first_stream_data.columns[:high]).to eql(47.8)
    expect(first_stream_data.columns[:tick]).to eql("\x00")
    expect(first_stream_data.columns[:low]).to eql(47.77)
    expect(first_stream_data.columns[:close]).to eql(47.81)
    expect(first_stream_data.columns[:tradetime_ruby]).to eql(Time.parse("2014-07-16 19:17:19 -0400"))
    expect(first_stream_data.columns[:quotetime_ruby]).to eql(Time.parse("2014-07-16 20:00:00 -0400"))

  end


  # This tests the behavior of a successful connection and download of streaming data from TDA.
  # The way this test works is it connects to the API streaming server for 15 seconds,
  # then it checks for the following conditions:
  # 1) a success message was received
  # 2) a heartbeat message was received
  # 3) a streaming quote message was received
  # 4) the stream was saved to a file
  # 5) any unexpected exception thrown will caused the Rspec test to fail
  #
  # Note that this test is skipped if connect_to_stream is false.
  it "downloads and processes streaming data from TDA and saves the stream to a file" do

    if connect_to_stream
      pout "Testing TD Ameritrade Level 1 quote data stream"

      # Test conditions that will be checked later
      has_heartbeat_message = false
      has_successful_connect_message = false
      has_quote_stream_message = false

      request_fields = [:volume, :last, :bid, :symbol, :ask, :quotetime, :high, :low, :close, :tradetime, :tick]
      symbols = watchlist
      file_name = File.join(Dir.pwd, 'spec', 'test_data', 'sample_stream_rspec_test.binary')
      i = 1

      File.delete(file_name) if File.exists? file_name

      streamer.output_file = file_name
      streamer.run(symbols: symbols, request_fields: request_fields) do |data|
        data.convert_time_columns
        case data.stream_data_type
          when :heartbeat
            pout "Heartbeat: #{data.timestamp}"
            has_heartbeat_message = true
          when :snapshot
            if data.service_id == "100"
              pout "Snapshot SID-#{data.service_id}: #{data.columns[:description]}"
              has_successful_connect_message = true if data.columns[:description]=='SUCCESS' && data.columns[:return_code]==0
            else
              pout "Snapshot: #{data}"
            end
          when :stream_data
            pout "#{i} Stream: #{data.columns}"
            has_quote_stream_message = true
          else
            pout "Unknown type of data: #{data}"
        end
        i += 1
        streamer.quit if i > 5 # We only need a few records
      end

      expect(has_heartbeat_message).to be_truthy
      expect(has_successful_connect_message).to be_truthy
      expect(has_quote_stream_message).to be_truthy
      expect(File.exists?(file_name)).to be_truthy
      expect(File.size(file_name)).to be > 10 # should have more than 10 bytes of data (arbitrary small number)
    else
      # this is only if we are skipping the test
      expect(true).to be_truthy
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