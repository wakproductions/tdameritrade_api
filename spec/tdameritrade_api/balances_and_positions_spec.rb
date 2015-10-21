require 'spec_helper'
require 'tdameritrade_api'
require 'pry'

describe TDAmeritradeApi::Client do
  let(:client) { RSpec.configuration.client }

  it 'gets the balances and positions hash' do
    account_id = client.accounts.first[:account_id]
    bp = client.get_balances_and_positions(account_id)

    expect(validate_bp_return_hash(bp)).to be_truthy
  end

  private

  def validate_bp_return_hash(hash)
    return false unless hash.has_key? "error"
    return false unless hash.has_key? "account_id"
    return false unless hash["error"].nil?

    return true
  end
end
