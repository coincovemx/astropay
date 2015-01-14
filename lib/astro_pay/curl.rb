module AstroPay
  class Curl
    def self.enable_ssl
      AstroPay.configuration.enable_ssl
    end

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