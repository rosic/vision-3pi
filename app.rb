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
API_DISCOVERY_FILE = "https://vision.googleapis.com/$discovery/rest?version=v1"

def api_url
  API_URL
end

def authorization
  # requires GOOGLE_APPLICATION_CREDENTIALS env variable
  # to point to json file with credentials
  scopes =  ["https://www.googleapis.com/auth/cloud-platform"]
  Google::Auth.get_application_default(scopes)
end

def client
  @client ||= Faraday.new(url: api_url) do |faraday|
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
  %w(
  http://media.expedia.com/hotels/1000000/20000/10500/10422/10422_205_b.jpg
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
      },
      {
        type: "SAFE_SEARCH_DETECTION",
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
    authorization.apply!(request.headers)
  end

  if response.success?
    JSON.parse(response.body)
  else
    raise response.body
  end
end

res = analyze(body)
pp res

if ARGV.first == "save"
  results = JSON.load(File.read("results.json")) || {}
  results.merge!(Hash[source_image_urls.zip(res["responses"])])
  File.write("results.json", JSON.dump(results))
end
