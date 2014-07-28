require 'spec_helper'
require 'tdameritrade_api'

describe TDAmeritradeApi::Client do
  let(:client) { RSpec.configuration.client }

  it "should be able to get the watchlists" do
    w = client.get_watchlists
    expect(w).to be_a(Array)
    expect(w.count).to be > 0
    wl = w.first

    expect(wl[:name]).to be_a(String)
    expect(wl[:id]).to be_a(String)
    expect(wl[:symbols]).to be_a(Array)
    expect(wl[:symbols].first).to be_a(String)
  end

  it "should be able to get a specific watchlist given a specific id"
  it "can create, edit, and delete a watchlist"  # a comprehensive test
end