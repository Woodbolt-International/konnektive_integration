class KonnektiveError < StandardError ; end

class KonnektiveApi
  attr_reader :login, :password

  def initialize(login, password)
    @login = login
    @password = password
  end

  def get_orders(start_date=nil, end_date=nil)
    query = URI.encode_www_form({
      loginId: login,
      password: password,
      startDate: start_date,
      endDate: end_date,
      resultsPerPage: 200
    })
    url = "https://api2.konnektive.com/order/query/?#{query}"

    response = api_request(url)
    if response['result'] == 'ERROR'
      if response['message'] == "No orders matching those parameters could be found"
        return []
      else
        raise ::KonnektiveError.new response["message"]
      end
    end

    response['message']['data']
  end

  def update_fulfillment(order_id, status, tracking_num, shipped_date)
    query = URI.encode_www_form({
      loginId: login,
      password: password,
      orderId: order_id,
      fulfillmentStatus: status,
      trackingNumber: tracking_num,
      dateShipped: shipped_date
    })
    url = "https://api.konnektive.com/fulfillment/update/?#{query}"

    response = api_request(url)
    if response['result'] == 'ERROR'
      raise ::KonnektiveError.new response["message"]
    end

    response["message"]
  end

  private
  def api_request(url)
    JSON.parse(HTTParty.get(url,
      timeout: 240,
      headers: { 'Content-Type' => 'application/json' }
    ).parsed_response)
  end
end
