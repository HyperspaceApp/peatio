# encoding: UTF-8
# frozen_string_literal: true

module BlockchainClient
  class Hyperspace < Base
    def initialize(*)
      super
      @json_rpc_endpoint = URI.parse(blockchain.server)
    end

    def endpoint
      @json_rpc_endpoint
    end

    def latest_block_number
      Rails.cache.fetch "latest_#{self.class.name.underscore}_block_number", expires_in: 5.seconds do
        path = '/consensus'
        rest_api(:get, path).fetch('height')
      end
    end

    def get_block(block_height)
      path = '/consensus/blocks?height=' + block_height.to_s
      rest_api(:get, path)
    end

    def to_address(tx)
      tx.fetch('siacoinoutputs').map{|v| normalize_address(v['unlockhash'])}
    end

    def normalize_address(address)
      address.downcase
    end

    def normalize_txid(txid)
      txid.downcase
    end

    def build_transaction(tx, current_block, address)
      entries = tx.fetch('siacoinoutputs').map do |item|

        next if item.fetch('value').to_d <= 0
        next if address != normalize_address(item['unlockhash'])

        {
          amount: convert_from_hastings(item.fetch('value').to_d),
          address: normalize_address(item['scriptPubKey']['addresses'][0])
        }
      end.compact

      { id:            normalize_txid(tx.fetch('id')),
        block_number:  current_block,
        entries:       entries }
    end

    def convert_from_hastings(h)
      return h / 1e24
    end

    # def get_unconfirmed_txns
    #   path = '/wallet/transactions'
    #   rest_api(:get, path).fetch('unconfirmedtransactions').map()
    # end

    # def get_raw_transaction(txid)
    #   json_rpc(:getrawtransaction, [txid, true]).fetch('result')
    # end

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
