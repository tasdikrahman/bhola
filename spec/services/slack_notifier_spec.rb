# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SlackNotifier do
  context '#webhook_url' do
    let(:webhook_url) { 'https://foo.slackwebhook.com' }
    let(:slack_notifier) { SlackNotifier.new(webhook_url) }

    it 'returns the webhook_url attribute' do
      expect(slack_notifier.webhook_url).to eq(webhook_url)
    end
  end

  context '#notify' do
    let(:webhook_url) { "https://foo.slackwebhook.com#{webhook_path}" }
    let(:webhook_port) { 443 }
    let(:webhook_host) { 'foo.slackwebhook.com' }
    let(:slack_notifier) { SlackNotifier.new(webhook_url) }
    let(:request_headers) do
      {
        'Content-Type' => 'application/json'
      }
    end
    let(:message) { 'test-message' }
    let(:request_body) do
      {
        'text': message.to_s
      }.to_json
    end
    let(:uri_double) { instance_double(URI) }
    let(:net_http_double) { instance_double(Net::HTTP, :use_ssl= => true) }
    let(:uri_https_double) { instance_double(URI::HTTPS, host: webhook_host, port: webhook_port, path: webhook_path) }
    let(:request_double) { instance_double(Net::HTTP::Post, :body= => request_body) }

    context 'when the webhook url is invalid' do
      context 'when url is valid, but the path is wrong' do
        let(:webhook_path) { '/invalid' }
        let(:response_double) { instance_double(Net::HTTPForbidden, :code => '403', :body => 'invalid_token') }

        it 'will return back the response code and body' do
          allow(net_http_double).to receive(:request).and_return(response_double)
          allow(URI).to receive(:parse).with(webhook_url).and_return(uri_https_double)
          allow(Net::HTTP).to receive(:new).with(webhook_host, webhook_port).and_return(net_http_double)
          allow(Net::HTTP::Post).to receive(:new).with(webhook_path, request_headers).and_return(request_double)

          response = slack_notifier.notify(message)

          expect(response.code).to eq('403')
          expect(response.body).to eq('invalid_token')
        end
      end

      context 'when the url is invalid' do
        let(:webhook_url) { 'invalid-domain.com' }

        context 'url is not a valid domain' do
          let(:webhook_path) { '/pathwouldnotmatter' }
          let(:http_error_response) { 'Failed to open TCP connection to :80 (Connection refused - connect(2) for nil port 80' }
          let(:http_error_response_to_s) { "Connection refused - #{http_error_response}" }
          let(:error_log) { "Error connecting to the slack webhook endpoint. Error: #{http_error_response_to_s}" }

          it 'will return back an error object back to the caller, mentioning the url provided is invalid' do
            allow(Rails.logger).to receive(:info)
            allow(URI).to receive(:parse).with(webhook_url).and_return(uri_https_double)
            allow(URI).to receive(:parse).with(webhook_url).and_return(uri_https_double)
            allow(Net::HTTP).to receive(:new).with(webhook_host, webhook_port).and_return(net_http_double)
            allow(Net::HTTP::Post).to receive(:new).with(webhook_path, request_headers).and_return(request_double)
            allow(net_http_double).
              to receive(:request).
              and_raise(Errno::ECONNREFUSED, http_error_response)

            slack_notifier.notify(message)

            expect(Rails.logger).
              to have_received(:info).with(error_log)
          end
        end
      end
    end

    context 'when the webhook url is valid' do
      let(:webhook_path) { '/services/foo/bar' }
      let(:response_double) { instance_double(Net::HTTPOK, :code => '200', :body => 'ok') }

      it 'will send a POST call to the webhook url with the message body' do
        allow(net_http_double).to receive(:request).and_return(response_double)
        allow(URI).to receive(:parse).with(webhook_url).and_return(uri_https_double)
        allow(Net::HTTP).to receive(:new).with(webhook_host, webhook_port).and_return(net_http_double)
        allow(Net::HTTP::Post).to receive(:new).with(webhook_path, request_headers).and_return(request_double)

        response = slack_notifier.notify(message)

        expect(response.code).to eq('200')
        expect(response.body).to eq('ok')
      end
    end
  end
end
