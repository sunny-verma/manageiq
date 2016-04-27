require 'rest-client'
require 'rubygems'
require 'json'
  class ManageIQ::Providers::Nuage::NetworkManager::VsdClient::Rest

    def initialize(server, user, password)
      @server=server
      @user=user
      @password=password
      @apiKey=''
      @headers = {'X-Nuage-Organization' => 'csp', "Content-Type" => "application/json; charset=UTF-8"}
    end

    def login
      @loginUrl = @server+"/me"
      RestClient::Request.execute(method: :get, url: @loginUrl, user: @user, password: @password, headers: @headers, :verify_ssl => false) { |response|
        case response.code
          when 200
            data = JSON.parse(response.body)
            data1 = data[0]
            @apiKey = data1["APIKey"]
            return true, data1["enterpriseID"]
          else
            return false, nil
        end
      }

    end

    def server
      return @server
    end

    def appendHeaders(key, value)
      @headers[key]=value
    end

    def get(url)
      if (@apiKey == '')
        login
      end
      RestClient::Request.execute(method: :get, url: url, user: @user, password: @apiKey, headers: @headers, :verify_ssl => false, :verify_ssl => false) { |response|
        return response
      }
    end

    def delete(url)
      if (@apiKey == '')
        login
      end
      RestClient::Request.execute(method: :delete, url: url, user: @user, password: @apiKey, headers: @headers, :verify_ssl => false) { |response|
        return response
      }
    end

    def put(url, data)
      if (@apiKey == '')
        login
      end

      RestClient::Request.execute(method: :put, data: data, url: url, user: @user, password: @apiKey, headers: @headers, :verify_ssl => false) { |response|
        return response
      }
    end

    def post(url, data)
      if (@apiKey == '')
        login
      end

      RestClient::Request.execute(method: :post, data: data, url: url, user: @user, password: @apiKey, headers: @headers, :verify_ssl => false) { |response|
        return response
      }
    end

  end
