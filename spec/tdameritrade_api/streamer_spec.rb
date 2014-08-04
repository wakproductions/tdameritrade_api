require 'spec_helper'

describe TDAmeritradeApi::Client do
  let(:client) { RSpec.configuration.client }
  let(:streamer) {client.create_streamer}
  let(:mock_data_file) { File.join(Dir.pwd, 'spec', 'test_data', 'sample_stream.binary') }

  it 'should create a valid streamer' do
    expect(streamer.streamer_info_response).to be_a(String)
    expect(streamer.authentication_params).to be_a(Hash)
  end

  # This test is to provide a controlled input for testing against the stream processing routines.
  # It is more useful than connecting to the stream directly because you may not have much data coming in
  # depending on whether the market is open when you run the test against a live connection.
  it 'should be able to process a complex stream saved to a file' do
    streamer = TDAmeritradeApi::Streamer::Streamer.new(read_from_file: mock_data_file)
    streamer.run do |data|
      case data.stream_data_type
        when :heartbeat
          puts "Heartbeat: #{data.timestamp}"
        when :snapshot
          if data.service_id == "100"
            puts "Snapshot SID-#{data.service_id}: #{data.message}"
          else
            puts "Snapshot: #{data}"
          end
        when :stream_data
          #puts "Stream: #{data}"
          cols = data.columns.each { |k,v| "#{k}: #{v}   "}
          puts "Stream: #{cols}"
        else
          puts "Unknown type of data: #{data}"
      end
      puts data
    end
  end


  # !!! THIS TEST IS NOT COMPLETE WITH EXPECTATIONS YET !!!
  it "should be able to start the streamer" do
    # streamer.run(read_from_file: File.join(Dir.pwd, 'spec', 'test_data', 'sample_stream.binary') ) do |data|
    #   case data.stream_data_type
    #     when :heartbeat
    #       puts "Heartbeat: #{data.timestamp}"
    #     when :snapshot
    #       if data.service_id == "100"
    #         puts "Snapshot SID-#{data.service_id}: #{data.message}"
    #       else
    #         puts "Snapshot: #{data}"
    #       end
    #     when :stream_data
    #       puts "Stream: #{data.message}"
    #     else
    #       puts "Unknown type of data: #{data}"
    #   end
    #   puts data
    # end

    # This code here is to manually test whether the streamer is running in an asynchronous thread
    # 100.times do |time|
    #   sleep 2
    #   puts "main thread #{time}"
    # end
  end
end