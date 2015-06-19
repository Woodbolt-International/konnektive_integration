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
      status: order['orderStatus'].downcase,
      channel: 'konnektive',
      email: order['emailAddress'],
      user_id: order['customerId'],
      currency: "USD",
      placed_on: order['dateCreated'],
      updated_at: order['dateCreated'],
      totals: totals(order),
      line_items: line_items(order),
      adjustments: adjustments(order),
      shipping_address: shipping_address(order),
      billing_address: billing_address(order),
      payments: payments(order),
      shipments: shipments(order)
    }
  end

  # helpers
  def totals(order)
    {
      item: line_items(order).map {|e| e[:price]}.inject(:+),
      adjustment: adjustments(order).map {|e| e[:value]}.inject(:+),
      tax: order['salesTax'].to_s.to_f,
      shipping: order['baseShipping'].to_s.to_f,
      payment: payments(order).map {|e| e[:amount]}.inject(:+),
      order: order['totalAmount'].to_s.to_f,
      discount: order['totalDiscount'].to_s.to_f
    }
  end

  def line_items(order)
    items = order['items'] || {}
    items.keys.map do |id|
      item = order['items'][id]

      {
        id: item['orderItemId'].to_s.to_f,
        product_id: item['productId'].to_s.to_f,
        name: item['name'],
        quantity: item['qty'].to_s.to_f,
        price: item['price'].to_s.to_f,
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

  def adjustments(order)
    base = [
      { name: 'tax', value: order['salesTax'].to_s.to_f, code: 'TAX' },
      { name: 'shipping', value: order['baseShipping'].to_s.to_f, code: 'FRT' }
    ]

    if  order['couponCode']
      return base + [{name: order['couponCode'], value: order['totalDiscount'].to_s.to_f, code: order['couponCode'].upcase }]
    end

    base
  end

  def payments(order)
    [
      {
        # "number": 63, # ignored
        "status": "completed",
        "amount": 210,
        "payment_method": order['paySource'].titleize,
        amount: order['totalAmount'].to_s.to_f
      }
    ]
  end

  def shipments(order)
    (order['fulfillments'] || []).map do |s|
      {
        number: s['fulfillmentId'],
        #cost: s['cost'],
        status: s['status'].downcase,
        stock_location: "Konnektive",
        shipping_method: s['shipCarrier'] || "UPS",
        shipping_method_code: s['shipMethod'] || "GND",
        tracking: s['trackingNumber'],
        #updated_at: s['dateCreated'],
        shipped_at: s['dateShipped']
        #items: s['items']
      }
    end
  end
end
