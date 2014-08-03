require 'spec_helper'

describe TDAmeritradeApi::Client do
  let(:client) { RSpec.configuration.client }
  let(:streamer) {client.create_streamer}

  it 'should create a valid streamer' do
    expect(streamer.streamer_info_response).to be_a(String)
    expect(streamer.authentication_params).to be_a(Hash)
  end


  # !!! THIS TEST IS NOT COMPLETE WITH EXPECTATIONS YET !!!
  it "should be able to start the streamer" do
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
          puts "Stream: #{data.message}"
        else
          puts "Unknown type of data: #{data}"
      end
      puts data
    end

    # This code here is to manually test whether the streamer is running in an asynchronous thread
    100.times do |time|
      sleep 2
      puts "main thread #{time}"
    end
  end
end