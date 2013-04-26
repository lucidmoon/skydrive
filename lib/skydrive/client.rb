module Skydrive
  # The client class
  class Client
    attr_reader :access_token
    include HTTMultiParty
    include Operations
    base_uri "https://apis.live.net/v5.0/"
    format :json
    def initialize access_token
      @access_token = access_token
      self.class.default_params :access_token => @access_token.token
    end

    # Do a 'get' request
    # @param [String] url the url to get
    # @param [Hash] options Additonal options to be passed
    def get url, options={}
      response = filtered_response(self.class.get(url, {:query => options}))
    end

    # Do a 'post' request
    # @param [String] url the url to post
    # @param [Hash] options Additonal options to be passed
    def post url, options={}
      response = filtered_response(self.class.post(url, {:body => options}))
    end

    # Do a 'move' request
    # @param [String] url the url to post
    # @param [Hash] options Additonal options to be passed
    def move url, options={}
      response = filtered_response(self.class.move(url, {:body => options}))
    end

    # Do a 'delete' request
    # @param [String] url the url to post
    def delete url
      response = filtered_response(self.class.delete(url))
    end

    # Refresh the access token
    def refresh_access_token!
      @access_token = access_token.refresh!
      self.class.default_params :access_token => @access_token.token
      @access_token
    end

    # Return a Skdrive::Object sub class
    def object response
      if response.is_a? Array
        return response.collect{ |object| "Skydrive::#{object["type"].capitalize}".constantize.new(self, object)}
      else
        return "Skydrive::#{response["type"].capitalize}"
      end
    end

    private

    # Filter the response after checking for any errors
    def filtered_response response
      raise Skydrive::Error.new({"code" => "no_response_received", "message" => "Request didn't make through or response not received"}) unless response
      raise Skydrive::Error.new("code" => "http_error_#{response.response.code}", "message" => response.response.message) unless response.response.code == "200"
      raise Skydrive::Error.new(response["error"]) if response["error"]
      filtered_response = response.parsed_response
      raise Skydrive::Error.new(filtered_response["error"]) if filtered_response["error"]
      if filtered_response["data"]
        return Skydrive::Collection.new(self, filtered_response["data"])
      else
        return "Skydrive::#{filtered_response["type"].capitalize}".constantize.new(self, filtered_response)
      end
    end

  end
end