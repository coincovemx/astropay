=begin
    Class of AstroPay Card

    @author Luis Galaviz (galaviz.lm@gmail.com)
=end

module AstroPay
  class Card < AstroPay::Model

    # Input params
    attr_accessor :approval_code, :number, :ccv, :exp_date
    attr_accessor :amount, :unique_id, :invoice_num, :transaction_id
    attr_accessor :additional_params, :type

    def initialize(args={})
      config = AstroPay.configuration

      @x_login = config.card_x_login
      @x_trans_key = config.card_x_trans_key
      @sandbox = config.sandbox

      base_url = "https://#{'sandbox-' if @sandbox}api.astropaycard.com/"

      @x_version = "2.0"            #AstroPay API version (default "2.0")
      @x_delim_char = "|"           #Field delimit character, the character that separates the fields (default "|")
      @x_test_request = 'N'         #Change to N for production
      @x_duplicate_window = 30      #Time window of a transaction with the sames values is taken as duplicated (default 120)
      @x_method = "CC"
      @x_response_format = "json"   #Response format: "string", "json", "xml" (default: string) (recommended: json)

      @additional_params = Hash.new

      super

      @validator_url = "#{base_url}verif/validator"
      @transtatus_url = "#{base_url}verif/transtatus"
    end

    # Authorizes a transaction
    #
    # number AstroPay Card number (16 digits)
    # ccv AstroPay Card security code (CVV)
    # exp_date AstroPay Card expiration date
    # amount Amount of the transaction
    # unique_id Unique user ID of the merchant
    # invoice_num Merchant transaction identificator, i.e. the order number
    # additional_params Array of additional info that you would send to AstroPay for reference purpose.
    # return json of params returned by AstroPay capture API. Please see section 3.1.3 "Response" of AstroPay Card integration manual for more info
    def auth_transaction
      data = full_params.merge(
        'x_unique_id' => unique_id,
        'x_invoice_num' => invoice_num,
        'x_type' => "AUTH_ONLY"
      )

      astro_curl(@validator_url, data)
    end

    # Caputures previous authorized transaction
    #
    # auth_code The x_auth_code returned by auth_transaction method
    # number AstroPay Card number (16 digits)
    # ccv AstroPay Card security code (CVV)
    # exp_date AstroPay Card expiration date
    # amount Amount of the transaction
    # unique_id Unique user ID of the merchant
    # invoice_num Merchant transaction identificator, i.e. the order number
    # additional_params Array of additional info that you would send to AstroPay for reference purpose.
    # return json returned by AstroPay capture API. Please see section 3.1.3 "Response" of AstroPay Card integration manual for more info
    def capture_transaction
      data = full_params.merge(
        'x_unique_id' => unique_id,
        'x_invoice_num' => invoice_num,
        'x_auth_code' => approval_code,
        'x_type' => "CAPTURE_ONLY"
      )

      astro_curl(@validator_url, data)
    end

    # Authorize and capture a transaction at the same time (if it is possible)
    #
    # number AstroPay Card number (16 digits)
    # ccv AstroPay Card security code (CVV)
    # exp_date AstroPay Card expiration date
    # amount Amount of the transaction
    # unique_id Unique user ID of the merchant
    # invoice_num Merchant transaction identificator, i.e. the order number
    # additional_params Array of additional info that you would send to AstroPay for reference purpose.
    # return json returned by AstroPay capture API. Please see section 3.1.3 "Response" of AstroPay Card integration manual for more info
    def auth_capture_transaction
      data = full_params.merge(
        'x_unique_id' => unique_id,
        'x_invoice_num' => invoice_num,
        'x_type' => "AUTH_CAPTURE"
      )

      astro_curl(@validator_url, data)
    end

    # Refund a transaction
    #
    # transaction_id merchant invoice number sent in previus call of capture_transaction or auth_transaction
    # number AstroPay Card number (16 digits)
    # ccv AstroPay Card security code (CVV)
    # exp_date AstroPay Card expiration date
    # amount Amount of the transaction
    # additional_params Array of additional info that you would send to AstroPay for reference purpose.
    # return json returned by AstroPay capture API. Please see section 3.2.2 "Response" of AstroPay Card integration manual for more info
    def refund_transaction
      data = full_params.merge(
        'x_trans_id' => transaction_id,
        'x_type' => "REFUND"
      )

      astro_curl(@validator_url, data)
    end

    # VOID a transaction
    #
    # transaction_id merchant invoice number sent in previus call of capture_transaction or auth_transaction
    # number AstroPay Card number (16 digits)
    # ccv AstroPay Card security code (CVV)
    # exp_date AstroPay Card expiration date
    # amount Amount of the transaction
    # additional_params Array of additional info that you would send to AstroPay for reference purpose.
    # return json returned by AstroPay capture API. Please see section 3.2.2 "Response" of AstroPay Card integration manual for more info
    def void_transaction
      data = full_params.merge(
        'x_trans_id' => transaction_id,
        'x_type' => "VOID"
      )

      astro_curl(@validator_url, data)
    end

    # Checks the status of a transaction
    #
    # invoice_num The merchant id sent in the transaction
    # type 0 for basic info, 1 for detailed info
    # return json. Please see section 3.2.3 of APC integration manual from more details.
    def check_transaction_status
      data = basic_credentials.merge(
        'x_trans_key' => @x_trans_key,
        'x_invoice_num' => invoice_num,
        'x_type' => (type || 0)
      )

      astro_curl(@transtatus_url, data)
    end

    def astro_curl(url, params_hash)
      AstroPay::Curl.post(url, params_hash)
    end

    def calculate_control(transaction_id, amount)
      Digest::MD5.hexdigest("#{@x_login}#{transaction_id}#{amount}");
    end

    private

    def basic_credentials
      {
        'x_login' => @x_login,
        'x_tran_key' => @x_trans_key,
        'x_delim_char' => @x_delim_char,
        'x_test_request' => @x_test_request,
        'x_response_format' => @x_response_format
      }
    end

    def full_credentials
      basic_credentials.merge(
        'x_method' => @x_method,
        'x_version' => @x_version,
        'x_duplicate_window' => @x_duplicate_window
      )
    end

    def basic_variables
      {
        'x_card_num' => number,
        'x_card_code' => ccv,
        'x_exp_date' => exp_date,
        'x_amount' => amount
      }
    end

    def full_params
      full_credentials.merge(
        additional_params
      ).merge(
        basic_variables
      )
    end
  end
end