# encoding: UTF-8
# frozen_string_literal: true

module WalletClient
  class Hyperspace < Base

    def initialize(*)
      super
      @json_rpc_endpoint = URI.parse(wallet.uri)
    end

    def create_address!(options = {})
      path = '/wallet/address'
      { address: normalize_address(rest_api(:post, path).fetch('address')) }
    end

    def create_withdrawal!(issuer, recipient, amount, options = {})
      path = '/wallet/spacecash'
      rest_api(:post, path, {
          destination:      normalize_address(recipient.fetch(:address)),
          amount:           convert_to_hastings(amount).to_s
      }.compact).fetch('transactionids').last.yield_self(&method(:normalize_txid))
    end

    def inspect_address!(address)
      { address:  normalize_address(address),
        is_valid: valid_address?(normalize_address(address)) }
    end

    def normalize_address(address)
      address.downcase
    end

    def normalize_txid(txid)
      txid.downcase
    end

    def convert_to_hastings(amount)
      return amount * 1e24
    end

    def valid_address?(address)
      address.to_s.match?(/^([0-9a-z]{76})$/i)
    end

  protected

    def connection
      Faraday.new(@json_rpc_endpoint).tap do |connection|
        unless @json_rpc_endpoint.password.blank?
          connection.basic_auth(@json_rpc_endpoint.user, @json_rpc_endpoint.password)
        end
      end
    end
    memoize :connection

    def rest_api(verb, path, data = nil, raise_error = true)
      args = [path]

      if data
        if verb.in?(%i[ post put patch ])
          args << data.compact.to_json
          args << { 'Content-Type' => 'application/json' }
        else
          args << data.compact
          args << {}
        end
      else
        args << nil
        args << {}
      end

      args.last['Accept']        = 'application/json'
      args.last['User-agent']        = 'Hyperspace-Agent'

      response = connection.send(verb, *args)
      Rails.logger.debug { response.describe }
      response.assert_success! if raise_error
      JSON.parse(response.body)
    end
  end
end
