require 'sinatra/base'
require 'net/http'
require 'uri'
require 'json'
require 'yaml'
require 'time'

module HabVersionMonitor
  class Server < Sinatra::Base
    get '/' do
      @pkgs = {}
      config = YAML.load_file('config.yml')
      @bldr_url = config['bldr_url'] || 'https://bldr.habitat.sh'
      @refresh_interval_seconds  = config['refresh_interval_seconds'] || 30
      config['pkgs'].each do |pkg|
        @pkgs[pkg['name']] = []
        pkg['targets'].each do |target|
          pkg['channels'].each do |channel|
            puts 'here!'
            uri = URI.parse("#{@bldr_url}/v1/depot/channels/#{pkg['origin']}/#{channel}/pkgs/#{pkg['name']}/latest?target=#{target}")
            response = Net::HTTP.get_response(uri)
            json = JSON.parse(response.body)
            json['channel'] = channel
            @pkgs[pkg['name']] << json
          end
        end
      end
      erb :index
    end

    get '/config' do
      @config = YAML.load_file('config.yml')
      erb :config
    end
  end
end
