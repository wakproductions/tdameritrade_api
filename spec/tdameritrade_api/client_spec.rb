require 'spec_helper'
require 'tdameritrade_api'

describe "Client" do
  let(:client) do
    client = TDAmeritradeApi::Client.new
    client.login
    client
  end

  it "should be able to get recent daily price history" do
    result = client.get_daily_price_history "KNDI", '20140101'
    puts result.last.to_s
  end

  it "should not be able to get any data unless logged in" do

  end

  it "should be able to download the daily data for a stock" do

  end

  it "should be able to download the minute history data for a stock" do

  end

end