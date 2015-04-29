if ENV['RACK_ENV'] != 'production'
  require 'dotenv'
  Dotenv.load
end

Dir['./lib/**/*.rb'].each(&method(:require))
require 'sinatra'

class KonnektiveIntegration < Sinatra::Base
  set :logging, true

  configure do
    set :api, KonnektiveApi.new(ENV['KONNEKTIVE_LOGIN'], ENV['KONNEKTIVE_PASSWORD'])
  end

  before do
    content_type 'application/json'
  end

  post '/get_orders' do
    date_start = Date.today.prev_day.strftime("%m/%d/%Y")
    orders = settings.api.get_orders(date_start)
    WombatDataAdapter.new(orders).to_wombat
  end
end
