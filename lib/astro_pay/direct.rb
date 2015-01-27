=begin
    Class of AstroPay Direct

    @author Luis Galaviz (galaviz.lm@gmail.com)
=end

module AstroPay
  class Direct < AstroPay::Model

    # Input params
    attr_accessor :invoice, :amount, :iduser, :bank, :country, :currency
    attr_accessor :description, :cpf, :sub_code, :return_url, :confirmation_url
    attr_accessor :response_type

    # Creates a new instance of [AstroPay::Direct].
    #
    # @param  attributes [Hash] with the following fields: :invoice, :amount,
    #         :iduser, :bank, :country, :currency, :description, :cpf,
    #         :sub_code, :return_url, :confirmation_url.
    # @return [AstroPay::Direct] object.
    def initialize(args = {})
      config = AstroPay.configuration

      @x_login =  config.direct_x_login
      @x_trans_key = config.direct_x_trans_key
      @x_login_for_webpaystatus = config.direct_x_login_for_webpaystatus
      @x_trans_key_for_webpaystatus = config.direct_x_trans_key_for_webpaystatus
      @secret_key = config.direct_secret_key
      @sandbox = config.sandbox
      @response_type = 'json'

      super

      subdomain = 'sandbox.' if @sandbox

      @astro_urls = {
        "create" => "https://#{subdomain}astropaycard.com/api_curl/apd/create",
        "status" => "https://#{subdomain}astropaycard.com/apd/webpaystatus",
        "exchange" => "https://#{subdomain}astropaycard.com/apd/webcurrencyexchange",
        "banks" => "https://#{subdomain}astropaycard.com/api_curl/apd/get_banks_by_country"
      }
    end

    # Creates a new transaction.
    #
    # @return [Hash] of the response that includes the URL to where an user
    #         should be redirected to validate and complete the process. If
    #         there is an error, the [String] response is returned.
    def create
      params_hash = {
        'x_login' => @x_login,
        'x_trans_key' => @x_trans_key,
        'x_invoice' => invoice,
        'x_amount' => amount,
        'x_iduser' => iduser,
        'x_bank' =>   bank,
        'x_country' => country,
        'x_sub_code' => sub_code,
        'type' => response_type
      }

      message_to_control = "#{invoice}D#{amount}P#{iduser}A"

      sha256 = OpenSSL::Digest::SHA256.new
      control = OpenSSL::HMAC.hexdigest(sha256, [@secret_key].pack('A*'), [message_to_control].pack('A*'))
      control = control.upcase

      params_hash['control'] = control
      params_hash['x_currency'] = currency if currency
      params_hash['x_description'] = description if description
      params_hash['x_cpf'] = cpf if cpf
      params_hash['x_return'] = return_url if return_url
      params_hash['x_confirmation'] = confirmation_url if confirmation_url

      astro_curl(@astro_urls['create'], params_hash)
    end

    # Requests a list of valid banks by country.
    #
    # @return [Hash] of the response that includes the list of banks. If there 
    #         is an error, the [String] response is returned.
    def get_banks_by_country
      params_hash = {
        # Mandatory
        'x_login' => @x_login,
        'x_trans_key' => @x_trans_key,
        'country_code' => country,
        'type' => response_type
      }

      astro_curl(@astro_urls['banks'], params_hash)
    end

    # Requests the status of a transaction.
    #
    # @return [Hash] of the response that includes the transaction status. If
    #         there is an error, the [String] response is returned.
    def get_invoice_status
      params_hash = {
        # Mandatory
        'x_login' => @x_login_for_webpaystatus,
        'x_trans_key' => @x_trans_key_for_webpaystatus,
        'x_invoice' => invoice,
        'x_response_format' => response_type
      }

      astro_curl(@astro_urls['status'], params_hash)
    end

    # Requests the exchange rate from USD to the currency of a target country.
    #
    # @return [Hash] of the response that includes the exchange rate. If there
    #         is an error, the [String] response is returned.
    def get_exchange
      params_hash = {
        # Mandatory
        'x_login' => @x_login_for_webpaystatus,
        'x_trans_key' => @x_trans_key_for_webpaystatus,
        'x_country' => country,
        'x_amount' => amount
      }

      astro_curl(@astro_urls['exchange'], params_hash)
    end

    # Makes a request to the AstroPay API.
    #
    # @param  url [String] endpoint for the AstroPay API.
    # @param  params [Hash] data and options for the request.
    # @return [Hash] of the successful response or [String] of the response if
    #         an error rises.
    def astro_curl(url, params_hash)
      AstroPay::Curl.post(url, params_hash)
    end
  end
end
