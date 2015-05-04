class WombatDataAdapter
  attr_reader :data, :output

  def initialize(data=[])
    @data = data
    @output = []
  end

  def to_wombat
    data.map do |order|
      build_order(order)
    end
  end

  private
  def build_order(order)
    {
      id: "KN#{order['clientOrderId']}",
      status: order['orderStatus'],
      channel: 'konnektive',
      email: order['emailAddress'],
      currency: "USD",
      placed_on: order['dateCreated'],
      updated_at: order['dateCreated'],
      line_items: order['items'].keys.map { |id|
        item = order['items'][id]

        {
          id: item['orderItemId'],
          product_id: item['productId'],
          name: item['name'],
          quantity: item['qty'],
          price: item['price']
        }
      }
    }
  end
end
