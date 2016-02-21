#! /usr/bin/env ruby

require 'dotenv'
require 'googleauth'
require 'faraday'
require 'json'
require 'open-uri'
require 'base64'
require 'pp'

Dotenv.load
API_URL = "https://vision.googleapis.com/v1/images:annotate"
#API_DISCOVERY_FILE = "https://vision.googleapis.com/$discovery/rest?version=v1"
#scopes =  ["https://www.googleapis.com/auth/cloud-platform"]
#authorization = Google::Auth.get_application_default(scopes)
#require 'pry'; binding.pry

def api_url
  "#{API_URL}?key=#{ENV["API_KEY"]}"
end

def client
  @client ||= Faraday.new(url: api_url) do |faraday|
    #faraday.request(:url_encoded)
    faraday.response :logger
    faraday.adapter(Faraday.default_adapter)
  end
end

def image_content(url)
  Base64.encode64(
    open(url).read
  )
end

def source_image_urls
  # 1st set
  #http://media.expedia.com/hotels/2000000/1420000/1410600/1410527/1410527_102_b.jpg
  #http://media.expedia.com/hotels/2000000/1420000/1410600/1410527/1410527_28_b.jpg
  #http://media.expedia.com/hotels/2000000/1420000/1410600/1410527/1410527_92_b.jpg
  # 2nd set
  #http://media.expedia.com/hotels/1000000/20000/18000/17912/17912_299_b.jpg
  #http://media.expedia.com/hotels/1000000/20000/18000/17912/17912_287_b.jpg
  #http://media.expedia.com/hotels/1000000/20000/18000/17912/17912_289_b.jpg
  #http://media.expedia.com/hotels/1000000/20000/18000/17912/17912_285_b.jpg
  #http://media.expedia.com/hotels/1000000/20000/18000/17912/17912_335_b.jpg
  #http://media.expedia.com/hotels/1000000/20000/18000/17912/17912_365_b.jpg
  # 3rd set
  %w(
  http://media.expedia.com/hotels/1000000/890000/889800/889785/889785_90_b.jpg
  http://media.expedia.com/hotels/1000000/890000/889800/889785/889785_75_b.jpg
  http://media.expedia.com/hotels/1000000/890000/889800/889785/889785_73_b.jpg
  http://media.expedia.com/hotels/1000000/890000/889800/889785/889785_81_b.jpg
  http://media.expedia.com/hotels/1000000/890000/889800/889785/889785_87_b.jpg
  http://media.expedia.com/hotels/1000000/890000/889800/889785/889785_78_b.jpg
  http://s3.amazonaws.com/ht_images_staging/deploy@ip-172-31-10-187_172.31.10.187/attachments/files/504006/original.jpg?1455858891
  )
end

def image_request(souce_imageurl)
  {
    image: {
      content: image_content(souce_imageurl)
    },
    features: [
      {
        type: "LABEL_DETECTION",
      }
    ],
  }
end

def body
  {
    requests: source_image_urls.map(&method(:image_request))
  }
end

def analyze(body)
  response = client.post do |request|
    request.body = JSON.dump(body)
    request.headers["Content-Type".freeze] = "application/json".freeze
    request.headers["Accept".freeze] = "application/json".freeze
    #authorization.apply(request.headers)
  end

  if response.success?
    JSON.parse(response.body)
  else
    response.body
  end
end

pp analyze(body)
