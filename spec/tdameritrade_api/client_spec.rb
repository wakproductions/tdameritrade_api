require 'spec_helper'
require 'tdameritrade_api'

describe TDAmeritradeApi::Client do
  let(:client) do
    client = TDAmeritradeApi::Client.new
    client.login
    client
  end

  it "should populate certain instance variables after logging in" do

  end

  it "should be able to get recent daily price history" do
    result = client.get_daily_price_history "KNDI", '20140707'
    #=> [{:open=>14.88, :high=>15.58, :low=>14.65, :close=>14.85, :volume=>36713.1, :timestamp=>2014-07-07 00:00:00 -0400, :interval=>:day}]

    expect(result).to be_a Array
    expect(result.length).to eq(1)
    price_bar = result.first
    expect(price_bar[:open]).to be_a_kind_of Numeric
    expect(price_bar[:high]).to be_a_kind_of Numeric
    expect(price_bar[:low]).to be_a_kind_of Numeric
    expect(price_bar[:close]).to be_a_kind_of Numeric
    expect(price_bar[:volume]).to be_a_kind_of Numeric
    expect(price_bar[:timestamp]).to be_a_kind_of Time
  end

  it "should not be able to get any data unless logged in" do

  end

  it "should be able to download the daily data for a stock" do

  end

  it "should be able to download the minute history data for a stock" do

  end

end