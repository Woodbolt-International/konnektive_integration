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
      status: order['orderStatus'].titleize,
      channel: 'konnektive',
      email: order['emailAddress'],
      currency: "USD",
      placed_on: order['dateCreated'],
      updated_at: order['dateCreated'],
      line_items: line_items(order),
      shipping_address: shipping_address,
      billing_address: billing_address
    }
  end

  # helpers
  def line_items(order)
    order['items'].keys.map do |id|
      item = order['items'][id]

      {
        id: item['orderItemId'],
        product_id: item['productId'],
        name: item['name'],
        quantity: item['qty'],
        price: item['price'],
        sku: item['productId']
      }
    end
  end

  def billing_address(order)
    {
      firstname: order['firstName'],
      lastname: order['lastName'],
      address1: order['address1'],
      address2: order['address2'],
      city: order['city'],
      state: order['state'],
      country: order['country'],
      zipcode: order['postalCode'],
      phone: order['phoneNumber']
    }
  end

  def shipping_address(order)
    {
      firstname: order['shipFirstName'],
      lastname: order['shipLastName'],
      address1: order['shipAddress1'],
      address2: order['shipAddress2'],
      city: order['shipCity'],
      state: order['shipState'],
      country: order['shipCountry'],
      zipcode: order['shipPostalCode'],
      phone: order['phoneNumber']
    }
  end
end
