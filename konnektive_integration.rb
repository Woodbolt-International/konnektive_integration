require 'sinatra'
require 'endpoint_base'

Dir['./lib/**/*.rb'].each(&method(:require))

class KonnektiveIntegration < EndpointBase::Sinatra::Base
  set :logging, true
  attr_reader :api

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
