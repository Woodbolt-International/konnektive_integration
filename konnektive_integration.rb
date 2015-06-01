require 'sinatra'
require 'bugsnag'
require 'endpoint_base'

Bugsnag.configure do |config|
  config.api_key = "cd3ae54909a0f5fe5a1792b9c84f388b"
end

Dir['./lib/**/*.rb'].each(&method(:require))

class KonnektiveIntegration < EndpointBase::Sinatra::Base
  set :logging, true
  attr_reader :api
  use Bugsnag::Rack

  before do
    content_type 'application/json'
    @api = KonnektiveApi.new(@config['KONNEKTIVE_LOGIN'], @config['KONNEKTIVE_PASSWORD'])
  end

  post '/get_orders' do
    date_start = Date.today.strftime("%m/%d/%Y")
    begin
      orders = api.get_orders(date_start)
      WombatDataAdapter.new(orders).to_wombat.each do |order|
        add_object :order, order
      end
      result 200, 'The orders were imported correctly'
    rescue KonnektiveError => e
      result 500, e.message
    end
  end

end
