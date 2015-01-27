=begin
    Class of AstroPay Card

    @author Luis Galaviz (galaviz.lm@gmail.com)
=end

module AstroPay
  class Card < AstroPay::Model

    # Input params
    attr_accessor :approval_code, :number, :ccv, :exp_date, :amount, :unique_id
    attr_accessor :invoice_num, :transaction_id, :additional_params, :type

    # Creates a new instance of [AstroPay::Card].
    #
    # @param  attributes [Hash] with the following fields: :approval_code,
    #         :number, :ccv, :exp_date, :amount, :unique_id :invoice_num,
    #         :transaction_id, :additional_params, :type.
    # @return [AstroPay::Card] object.
    def initialize(args = {})
      config = AstroPay.configuration

      @x_login = config.card_x_login
      @x_trans_key = config.card_x_trans_key
      @sandbox = config.sandbox

      base_url = "https://#{'sandbox-' if @sandbox}api.astropaycard.com/"

      # AstroPay API version (default "2.0")
      @x_version = "2.0"
      # Field delimiter (default "|")
      @x_delim_char = "|"
      # Change to N for production
      @x_test_request = 'N'
      # Time window of a transaction with the sames values is taken as
      # duplicated (default 120)
      @x_duplicate_window = 30
      @x_method = "CC"
      # Response format:
      # "string", "json", "xml" (default: string; recommended: json)
      @x_response_format = "json"

      @additional_params = Hash.new

      super

      @validator_url = "#{base_url}verif/validator"
      @transtatus_url = "#{base_url}verif/transtatus"
    end

    # Requests AstroPay to AUTHORIZE a transaction.
    #
    # @note   This method sends in the request the following data:
    #         'number', AstroPay Card number (16 digits);
    #         'ccv', AstroPay Card security code (CVV);
    #         'exp_date', AstroPay Card expiration date;
    #         'amount', Amount of the transaction;
    #         'unique_id', Unique user ID of the merchant;
    #         'invoice_num', Merchant transaction identifier, i.e. the order
    #         number;
    #         'additional_params', Array of additional info that you would send
    #         to AstroPay for reference purpose.
    # @return [Hash] response by AstroPay capture API. Please see section 3.1.3
    #         "Response" of AstroPay Card integration manual for more info.
    def auth_transaction
      data = full_params.merge(
        'x_unique_id' => unique_id,
        'x_invoice_num' => invoice_num,
        'x_type' => "AUTH_ONLY"
      )

      astro_curl(@validator_url, data)
    end

    # Requests AstroPay to CAPTURE the previous authorized transaction.
    #
    # @note   (See #auth_transaction) to known the data sent on the request.
    # @return [Hash] response by AstroPay capture API. Please see section 3.1.3
    #         "Response" of AstroPay Card integration manual for more info.
    def capture_transaction
      data = full_params.merge(
        'x_unique_id' => unique_id,
        'x_invoice_num' => invoice_num,
        'x_auth_code' => approval_code,
        'x_type' => "CAPTURE_ONLY"
      )

      astro_curl(@validator_url, data)
    end

    # Requests AstroPay to AUTHORIZE and CAPTURE a transaction at the same time
    # (if it is possible).
    #
    # @note   (See #auth_transaction) to known the data sent on the request.
    # @return [Hash] response by AstroPay capture API. Please see section 3.1.3
    #         "Response" of AstroPay Card integration manual for more info.
    def auth_capture_transaction
      data = full_params.merge(
        'x_unique_id' => unique_id,
        'x_invoice_num' => invoice_num,
        'x_type' => "AUTH_CAPTURE"
      )

      astro_curl(@validator_url, data)
    end

    # Requests AstroPay to REFUND a transaction.
    #
    # @note   This request includes the transaction_id merchant invoice number
    #         sent in previous call of capture_transaction or auth_transaction.
    #         (See #auth_transaction) to known the data sent on the request.
    # @return [Hash] response by AstroPay capture API. Please see section 3.1.3
    #         "Response" of AstroPay Card integration manual for more info.
    def refund_transaction
      data = full_params.merge(
        'x_trans_id' => transaction_id,
        'x_type' => "REFUND"
      )

      astro_curl(@validator_url, data)
    end

    # Requests AstroPay to VOID a transaction.
    #
    # @note   This request includes the transaction_id merchant invoice number
    #         sent in previous call of capture_transaction or auth_transaction.
    #         (See #auth_transaction) to known the data sent on the request.
    # @return [Hash] response by AstroPay capture API. Please see section 3.1.3
    #         "Response" of AstroPay Card integration manual for more info.
    def void_transaction
      data = full_params.merge(
        'x_trans_id' => transaction_id,
        'x_type' => "VOID"
      )

      astro_curl(@validator_url, data)
    end

    # Requests AstroPay the status of a transaction.
    #
    # @note  This request includes the basic credentials data and the following
    #        fields:
    #        'invoice_num', The merchant id sent in the transaction;
    #        'type', 0 for basic info, 1 for detailed info.
    # @return [Hash] response by AstroPay capture API. Please see section 3.1.3
    #         "Response" of AstroPay Card integration manual for more info.
    def check_transaction_status
      data = basic_credentials.merge(
        'x_trans_key' => @x_trans_key,
        'x_invoice_num' => invoice_num,
        'x_type' => (type || 0)
      )

      astro_curl(@transtatus_url, data)
    end

    # Makes a request to the AstroPay API.
    #
    # @param  url [String] endpoint for the AstroPay API.
    # @param  params [Hash] data and options for the request.
    # @return [Hash] of the successful response or [String] of the response if
    #         an error rises.
    def astro_curl(url, params)
      AstroPay::Curl.post(url, params)
    end

    # Generates an hexadecimal code intended to be used in the checksum of the
    # messages received.
    #
    # @param  transaction_id [String] merchant's id for the transaction.
    # @param  amount [Float] of the transaction.
    # @return [String] of 64 uppercase characters.
    def calculate_control(transaction_id, amount)
      Digest::MD5.hexdigest("#{@x_login}#{transaction_id}#{amount}")
    end

    private

    # Sets a collection with the basic credentials for the AstroPay API.
    #
    # @return [Hash] Please see section 3.4 of the AstroPay Card integration
    #                manual for more info.
    def basic_credentials
      {
        'x_login' => @x_login,
        'x_tran_key' => @x_trans_key,
        'x_delim_char' => @x_delim_char,
        'x_test_request' => @x_test_request,
        'x_response_format' => @x_response_format
      }
    end

    # Sets a collection with the complete credentials for the AstroPay API.
    #
    # @return [Hash] See the AstroPay Card integration manual for more info.
    def full_credentials
      basic_credentials.merge(
        'x_method' => @x_method,
        'x_version' => @x_version,
        'x_duplicate_window' => @x_duplicate_window
      )
    end

    # Sets a collection with the basic data of an AstroPay card.
    #
    # @return [Hash] See the AstroPay Card integration manual for more info.
    def basic_variables
      {
        'x_card_num' => number,
        'x_card_code' => ccv,
        'x_exp_date' => exp_date,
        'x_amount' => amount
      }
    end

    # Sets a collection with the credentials, the card data and additional
    # parameters to be used on API calls.
    #
    # @return [Hash] See #basic_credential, #full_credentials and
    #         #basic_variables.
    def full_params
      full_credentials.merge(
        additional_params
      ).merge(
        basic_variables
      )
    end
  end
end
