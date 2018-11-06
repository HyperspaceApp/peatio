# encoding: UTF-8
# frozen_string_literal: true

module WalletService
  class Hyperspace < Base

    def create_address(options = {})
      @client.create_address!(options)
    end

    # TODO: deal with fee substraction
    def collect_deposit!(deposit, options={})
      destination_address = destination_wallet(deposit).address
      pa = deposit.account.payment_address

      # this will automatically deduct fee from amount
      options = options.merge( subtract_fee: true )

      client.create_withdrawal!(
        { address: pa.address },
        { address: destination_address },
        deposit.amount,
        options
      )
    end

    def build_withdrawal!(withdraw, options = {})
      client.create_withdrawal!(
        { address: wallet.address },
        { address: withdraw.rid },
        withdraw.amount,
        options
      )
    end
  end
end
