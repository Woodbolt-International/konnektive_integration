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
      id: order_id(order),
      status: order['orderStatus'].downcase,
      channel: 'konnektive',
      email: order['emailAddress'],
      currency: "USD",
      placed_on: format_date(order['dateCreated']),
      updated_at: format_date(order['dateCreated']),
      totals: totals(order),
      adjustments: adjustments(order),
      shipping_instruction: nil,
      user_id: order['customerId'],
      considered_risky: false,
      line_items: line_items(order),
      payments: payments(order),
      shipping_address: shipping_address(order),
      billing_address: billing_address(order),
      shipments: shipments(order)
    }
  end

  def order_id(order)
    "KN#{order['clientOrderId']}"
  end

  def format_date(date_str)
    Time.parse(date_str).getutc.iso8601 if date_str
  end

  # DD: http://stackoverflow.com/questions/18533026/trim-a-trailing-0
  def trim_zero(num)
    i, f = num.to_i, num.to_f
    i == f ? i : f
  end

  # helpers
  def totals(order)
    {
      item: trim_zero( line_items(order).map {|e| e[:price]}.inject(:+) ),
      adjustment: trim_zero( adjustments(order).map {|e| e[:value]}.inject(:+) ),
      tax: trim_zero( order['salesTax'].to_s.to_f ),
      shipping: trim_zero( order['baseShipping'].to_s.to_f ),
      payment: trim_zero( payments(order).map {|e| e[:amount]}.inject(:+) ),
      order: trim_zero( order['totalAmount'].to_s.to_f ),
      discount: trim_zero( order['totalDiscount'].to_s.to_f ),
      handling: 0
    }
  end

  def line_items(order)
    items = order['items'] || {}
    items.keys.map do |id|
      item = order['items'][id]

      {
        id: item['orderItemId'].to_s.to_i,
        product_id: item['productId'].to_s.to_i,
        name: item['name'],
        quantity: item['qty'].to_s.to_i,
        price: item['price'].to_s.to_f,
        sku: item['productId'].to_s.to_i
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

    if order['couponCode']
      return base + [{name: order['couponCode'], value: order['totalDiscount'].to_s.to_f, code: order['couponCode'].upcase }]
    end

    base
  end

  def payments(order)
    [
      {
        id: order['orderId'].to_s.to_i,
        number: order['orderId'].to_s.to_i,
        status: "completed",
        amount: order['totalAmount'].to_s.to_f,
        payment_method: order['paySource'].titleize,
        payment_method_card: order['cardType'].to_s.downcase,
        source: {
          name: "#{order['firstName']} #{order['lastName']}",
          cc_type: order['cardType'].to_s.downcase,
          last_digits: order['cardLast4'].to_s.downcase
        }
      }
    ]
  end

  def shipments(order)
    (order['fulfillments'] || []).map do |s|
      {
        id: "KN#{s['fulfillmentId']}",
        order_id: order_id(order),
        email: order['emailAddress'],
        cost: order['baseShipping'].to_s.to_f / order['fulfillments'].count,
        status: s['status'].downcase,
        stock_location: "Konnektive",
        shipping_method: s['shipCarrier'] || "UPS",
        tracking: s['trackingNumber'],
        shipped_at: format_date(s['dateShipped']),
        totals: {}, # DD: not sure if read by AX here
        updated_at: format_date(s['dateCreated']),
        channel: 'konnektive',
        items: [], # DD: not sure if read by AX here
        shipping_method_code: s['shipMethod'] || "GND",
        billing_address: billing_address(order),
        shipping_address: shipping_address(order)
      }
    end
  end
end
