class KonnektiveApi
  attr_reader :login, :password

  def initialize(login, password)
    @login = login
    @password = password
  end

  def get_orders(start_date=nil, end_date=nil)
    url = "https://api2.konnektive.com/order/query/?loginId=#{login}&password=#{password}&startDate=#{start_date}&endDate=#{end_date}"
    response = HTTParty.get(url,
      timeout: 240,
      headers: { 'Content-Type' => 'application/json' }
    )
    response.parsed_response
  end
end
