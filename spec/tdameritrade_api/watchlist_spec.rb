require 'spec_helper'
require 'tdameritrade_api'

describe TDAmeritradeApi::Client do
  let(:client) do
    client = TDAmeritradeApi::Client.new
    client.login
    client
  end

  it "should be able to get the watchlists"
  it "should be able to get a specific watchlist given a specific id"
end