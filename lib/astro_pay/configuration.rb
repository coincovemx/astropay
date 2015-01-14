module AstroPay
  class Configuration
    #AstroPay Direct required attributes
    attr_accessor :direct_x_login, :direct_x_trans_key, :direct_x_login_for_webpaystatus
    attr_accessor :direct_x_trans_key_for_webpaystatus, :direct_secret_key

    #AstroPay Direct required attributes
    attr_accessor :card_x_login, :card_x_trans_key

    #Optional attributes
    attr_accessor :sandbox, :enable_ssl

    def initialize
      @sandbox = true
      @enable_ssl = true
    end
  end
end