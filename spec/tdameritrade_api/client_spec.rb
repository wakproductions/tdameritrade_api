require 'spec_helper'
require 'tdameritrade_api'

describe TDAmeritradeApi::Client do
  let(:client) { RSpec.configuration.client }
  let(:ticker_symbol) { 'PG' }

  it "should populate certain instance variables after logging in" do

  end

  it "should retrieve the last 2 days of 30 min data" do
    result = client.get_price_history(ticker_symbol, intervaltype: :minute, intervalduration: 30, periodtype: :day, period: 2)
    expect(result).to be_a Array
    expect(result.length).to eq(26) # 13 half hour periods in a trading day (not including extended hours) times 2
    validate_price_bar(result.first)
  end

  it "should retrieve a date range of data" do
    result = client.get_price_history(ticker_symbol, intervaltype: :daily, intervalduration: 1, startdate: Date.new(2014,7,22), enddate: Date.new(2014,7,25))
    expect(result).to be_a Array
    expect(result.length).to eq(4) # 13 half hour periods in a trading day (not including extended hours) times 2
    validate_price_bar(result.first)
  end

  it "should be able to get recent daily price history using get_daily_price_history" do
    result = client.get_daily_price_history ticker_symbol, '20140707', '20140707'
    #=> [{:open=>14.88, :high=>15.58, :low=>14.65, :close=>14.85, :volume=>36713.1, :timestamp=>2014-07-07 00:00:00 -0400, :interval=>:day}]

    expect(result).to be_a Array
    expect(result.length).to eq(1)
    validate_price_bar(result.first)
  end

  it "should not be able to get any data unless logged in" do

  end

  it "should be able to download the daily data for a stock" do

  end

  it "should be able to download the minute history data for a stock" do

  end

private
  def validate_price_bar(price_bar)
    expect(price_bar[:open]).to be_a_kind_of Numeric
    expect(price_bar[:high]).to be_a_kind_of Numeric
    expect(price_bar[:low]).to be_a_kind_of Numeric
    expect(price_bar[:close]).to be_a_kind_of Numeric
    expect(price_bar[:volume]).to be_a_kind_of Numeric
    expect(price_bar[:timestamp]).to be_a_kind_of Time
  end

end