require "astro_pay/version"

require 'json'
require 'active_support'
require 'active_support/core_ext'
require 'active_support/inflector'
require 'active_model'

require 'openssl'
require 'net/http'
require 'uri'
require 'json'
require 'digest/md5'

require 'astro_pay/configuration'
require 'astro_pay/curl'
require 'astro_pay/model'
require 'astro_pay/card'
require 'astro_pay/direct'

module AstroPay
  class << self
    attr_writer :configuration
  end

  # Gets the configuration attribute.
  #
  # @return [AstroPay::Configuration] object.
  def self.configuration
    @configuration ||= Configuration.new
  end

  # Allows to set the configuration passing a block where the values are set.
  def self.configure
    yield(configuration)
  end

  # Gets a new [AstroPay::Direct] instance with the given arguments.
  #
  # @param  args [Array] (See AstroPay::Direct#initialize).
  # @return [AstroPay::Direct] object.
  def self.direct(*args)
    Direct.new(*args)
  end

  # Gets a new [AstroPay::Card] instance with the given arguments.
  #
  # @params args [Array] (See AstroPay::Card#initialize).
  # @return [AstroPay::Card] object.
  def self.card(*args)
    Card.new(*args)
  end

  # Gets a new [AstroPay::Direct] instance with the given arguments and some
  # optional values. See the AstroPay Direct Manual.
  #
  # @param  invoice [String] unique transaction ID number at the merchant.
  # @param  amount [Float] the amount of the payment.
  # @param  iduser [String] user’s unique ID at the merchant / account number.
  # @param  country [String] country code.
  # @param  bank [String] bank code.
  # @param  sub_code [Int] mandatory parameter for PSPs.
  # @param  args [Hash] Other arguments.
  # @return [AstroPay::Direct] object.
  def self.create_direct(invoice, amount, iduser, country, bank='', sub_code=1, args={})
    direct(
      args.merge(
        invoice: invoice,
        amount: amount,
        iduser: iduser,
        bank: bank,
        country: country,
        sub_code: sub_code
      )
    ).create
  end

  # Gets a new [AstroPay::Card] instance with the given arguments and some
  # optional values. See the AstroPay Card Manual.
  #
  # @param  number [String] AstroPay Card number.
  # @param  ccv [Int] AstroPay Card security code.
  # @param  exp_date [String] expiration date of AstroPay Card. Format: MM/YYYY
  # @param  amount [Float] transaction amount.
  # @param  bank [String] bank code.
  # @param  unique_id [String] unique, anonymized identifier of users in the
  #         merchant system.
  # @param  invoice_num [String] unique identifier of merchant transaction.
  # @param  additional_params [Hash] other arguments.
  # @return [AstroPay::Card] object.
  def self.create_card(number, ccv, exp_date, amount, unique_id, invoice_num, additional_params={})
    card(
      number: number,
      ccv: ccv,
      exp_date: exp_date,
      amount: amount,
      unique_id: unique_id,
      invoice_num: invoice_num,
      additional_params: additional_params
    ).auth_capture_transaction
  end
end