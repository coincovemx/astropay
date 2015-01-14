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

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def self.direct(*args)
    Direct.new(*args)
  end

  def self.card(*args)
    Card.new(*args)
  end

  # Optional:
  # You can send a Hash containing the following accepted params:
  # :description, :currency, :cpf, :return_url, :confirmation_url
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