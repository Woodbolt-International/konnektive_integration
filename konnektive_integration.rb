require 'sinatra'
require 'bugsnag'
require 'endpoint_base'

Bugsnag.configure do |config|
  config.api_key = ENV['BUGSNAG_KEY']
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
    date_start = Date.today.prev_day.strftime("%m/%d/%Y")
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

  post '/update_fulfillment' do
    request.body.rewind  # in case someone already read it
    params = JSON.parse(request.body.read)['shipment']

    begin
      msg = api.update_fulfillment(
        params['order_id'],
        params['status'].upcase,
        params['tracking'],
        Date.parse(params['shipped_at']).strftime("%m/%d/%Y")
      )
      result 200, msg
    rescue KonnektiveError => e
      result 500, e.message
    end
  end
end
