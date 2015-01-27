module AstroPay
  class Curl

    # Gets the configuration flag for SSL use with Astropay connections.
    #
    # @return [Boolean]
    def self.enable_ssl
      AstroPay.configuration.enable_ssl
    end

    # Performs a POST request to the given URL with the given parameters.
    # @param  url [String] to where the request will be made.
    # @param  params_hash [Hash] parameters to be sent with the request.
    # @return [Hash] of the response or, if an error rises, [String] of
    #         the response content.
    # @note   When SSL is enabled, no certificate is actually verified due to
    #         SSLv3 incompatibilities.
    def self.post(url, params_hash)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)

      unless enable_ssl
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data(params_hash)
      response = http.request(request)

      begin
        JSON.parse(response.body)
      rescue
        response.body
      end
    end
  end
end
