# frozen_string_literal: true

# SlackNotifier is a generic class which will be used to send POST calls to the slack webhook
class SlackNotifier
  attr_reader :webhook_url

  def initialize(webhook_url)
    @webhook_url = webhook_url
  end

  def notify(message)
    uri = URI.parse(webhook_url)
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(uri.path, { 'Content-Type' => 'application/json' })
    request.body = { text: message.to_s }.to_json
    https.request(request)
  rescue Errno::ECONNREFUSED => e
    Rails.logger.info("Error connecting to the slack webhook endpoint. Error: #{e.message}")
    raise
  end
end
