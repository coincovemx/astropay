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

    def initialize(args={})
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

    def get_banks_by_country
      params_hash = {
        #Mandatory
        'x_login' => @x_login,
        'x_trans_key' => @x_trans_key,
        'country_code' => country,
        'type' => response_type
      }

      astro_curl(@astro_urls['banks'], params_hash)
    end

    def get_invoice_status
      params_hash = {
        #Mandatory
        'x_login' => @x_login_for_webpaystatus,
        'x_trans_key' => @x_trans_key_for_webpaystatus,
        'x_invoice' => invoice,
        'x_response_format' => response_type
      }

      astro_curl(@astro_urls['status'], params_hash)
    end

    def get_exchange
      params_hash = {
        #Mandatory
        'x_login' => @x_login_for_webpaystatus,
        'x_trans_key' => @x_trans_key_for_webpaystatus,
        'x_country' => country,
        'x_amount' => amount
      }

      astro_curl(@astro_urls['exchange'], params_hash)
    end

    def astro_curl(url, params_hash)
      AstroPay::Curl.post(url, params_hash)
    end
  end
end
