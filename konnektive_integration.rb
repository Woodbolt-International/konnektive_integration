if ENV['RACK_ENV'] != 'production'
  require 'dotenv'
  Dotenv.load
end

Dir['./lib/**/*.rb'].each(&method(:require))
require 'sinatra'

class KonnektiveIntegration < Sinatra::Base
  set :logging, true
  attr_reader :api

  before do
    @api = KonnektiveApi.new(ENV['KONNEKTIVE_LOGIN'], ENV['KONNEKTIVE_PASSWORD'])
  end

  # I think it should be a POST, not sure yet
  get '/get_orders' do
    date_start = Date.today.prev_day.strftime("%m/%d/%Y")
    api.get_orders(date_start)
  end
end
