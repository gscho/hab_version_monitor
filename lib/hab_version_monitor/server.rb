require 'sinatra/base'
require 'net/http'
require 'uri'
require 'json'
require 'yaml'
require 'time'

module HabVersionMonitor
  class Server < Sinatra::Base
    configure { set :server, :puma }
    get '/' do
      @pkgs = {}
      config = YAML.load_file(ENV.fetch('HVM_CONFIG_PATH', 'config.yml'))
      @bldr_url = config['bldr_url'] || 'https://bldr.habitat.sh'
      @refresh_interval_seconds  = config['refresh_interval_seconds'] || 30
      config['pkgs'].each do |pkg|
        @pkgs[pkg['name']] = []
        pkg['targets'].each do |target|
          pkg['channels'].each do |channel|
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
      @config = YAML.load_file(ENV.fetch('HVM_CONFIG_PATH', 'config.yml'))
      erb :config
    end
  end
end
