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

    response = JSON.parse(HTTParty.get(url,
      timeout: 240,
      headers: { 'Content-Type' => 'application/json' }
    ).parsed_response)

    raise ::KonnektiveError.new response["message"] if response['result'] == 'ERROR'
    response['message']['data']
  end
end
