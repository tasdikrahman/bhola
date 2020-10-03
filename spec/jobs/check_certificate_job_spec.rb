# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CheckCertificateJob, type: :job do
  it { expect(described_class).to be < ApplicationJob }

  context '#perform' do
    context 'when there are no domains being tracked' do
      it 'will log via rails logger that there are no domains being tracked' do
        allow(Rails.logger).to receive(:info)
        allow(Domain).to receive_message_chain(:all, :count).and_return(0)

        CheckCertificateJob.perform_now

        expect(Rails.logger).to have_received(:info).
          with('No domains are tracked as of now, please insert domains to be tracked')
      end
    end

    context 'when there are domains being tracked' do
      let(:fqdn) { 'foo.example.com' }
      let!(:domain) { Domain.create(fqdn: fqdn) }

      context 'when the domain tracked is not expiring within the buffer timezone' do
        it 'will log via rails logger that no tracked domains are expiring within the buffer period' do
          allow(Rails.logger).to receive(:info)
          allow_any_instance_of(Domain).to receive(:certificate_expiring?).and_return(false)

          CheckCertificateJob.perform_now

          expect(Rails.logger).to have_received(:info).with("#{fqdn} is not expiring within the buffer period")
        end
      end

      context 'when the domain tracked is expiring within the buffer timezone' do
        it 'will log via rails logger that the domain is expiring within the buffer period' do
          allow(Rails.logger).to receive(:info)
          allow_any_instance_of(Domain).to receive(:certificate_expiring?).and_return(true)

          CheckCertificateJob.perform_now

          expect(Rails.logger).to have_received(:info).with("#{fqdn} is expiring within the buffer period")
        end

        context 'when send_expiry_notifications_to_slack env var is set to false' do
          let(:slack_webhook_url) { 'foo.slackwebhook.com/bar/webhook' }

          it 'will not call SlackNotifier#notify' do
            allow_any_instance_of(Domain).to receive(:certificate_expiring?).and_return(true)
            allow(Figaro).to receive_message_chain(:env, :send_expiry_notifications_to_slack).and_return(false)
            allow(Figaro).to receive_message_chain(:env, :slack_webhook_url).and_return(slack_webhook_url)
            expect_any_instance_of(SlackNotifier).not_to receive(:notify).with(anything)

            CheckCertificateJob.perform_now
          end
        end

        context 'when send_expiry_notifications_to_slack env var is set to true' do
          context 'when slack_webhook_url is not empty' do
            let(:cert_not_before) { Time.parse('2012-10-1 8:00:00 Pacific Time (US & Canada)').utc }
            let(:message) { "Your #{fqdn} is expiring at #{cert_not_before}, please renew your cert" }
            let(:slack_webhook_url) { 'foo.slackwebhook.com/bar/webhook' }
            let(:response_double) { instance_double(Net::HTTPOK, :code => '200', :body => 'ok') }

            it 'will call SlackNotifier#notify' do
              allow_any_instance_of(Domain).to receive(:certificate_expiring?).and_return(true)
              allow_any_instance_of(Domain).to receive(:certificate_expiring_not_before).and_return(cert_not_before)
              allow(Figaro).to receive_message_chain(:env, :send_expiry_notifications_to_slack).and_return(true)
              allow(Figaro).to receive_message_chain(:env, :slack_webhook_url).and_return(slack_webhook_url)
              allow_any_instance_of(SlackNotifier).to receive(:notify).with(message).and_return(response_double)
              expect_any_instance_of(SlackNotifier).to receive(:notify).with(message).once

              CheckCertificateJob.perform_now
            end

            context 'response body is ok and status code is 200 for response returned by SlackNotifier#notify' do
              it 'will log using rails logger mentioning a successfull POST call to the slack webhook' do
                allow(Rails.logger).to receive(:info)
                allow_any_instance_of(Domain).to receive(:certificate_expiring?).and_return(true)
                allow_any_instance_of(Domain).to receive(:certificate_expiring?).and_return(true)
                allow_any_instance_of(Domain).to receive(:certificate_expiring_not_before).and_return(cert_not_before)
                allow(Figaro).to receive_message_chain(:env, :send_expiry_notifications_to_slack).and_return(true)
                allow(Figaro).to receive_message_chain(:env, :slack_webhook_url).and_return(slack_webhook_url)
                allow_any_instance_of(SlackNotifier).to receive(:notify).with(message).and_return(response_double)

                CheckCertificateJob.perform_now

                expect(Rails.logger).to have_received(:info).with("Expiry notification successfully sent to slack for domain #{fqdn}")
              end
            end

            context 'response body is invalid_token and status code is 403 for response returned by SlackNotifier#notify' do
              let(:response_double) { instance_double(Net::HTTPForbidden, :code => '403', :body => 'invalid_token') }

              it 'will log using rails logger mentioning a the error response body and status code for POST call to the slack webhook' do
                allow(Rails.logger).to receive(:info)
                allow_any_instance_of(Domain).to receive(:certificate_expiring?).and_return(true)
                allow_any_instance_of(Domain).to receive(:certificate_expiring?).and_return(true)
                allow_any_instance_of(Domain).to receive(:certificate_expiring_not_before).and_return(cert_not_before)
                allow(Figaro).to receive_message_chain(:env, :send_expiry_notifications_to_slack).and_return(true)
                allow(Figaro).to receive_message_chain(:env, :slack_webhook_url).and_return(slack_webhook_url)
                allow_any_instance_of(SlackNotifier).to receive(:notify).with(message).and_return(response_double)

                CheckCertificateJob.perform_now

                expect(Rails.logger).not_to have_received(:info).
                  with("Expiry notification successfully sent to slack for domain #{fqdn}")
                expect(Rails.logger).
                  to have_received(:info).
                  with("Expiry notification could not be sent for domain #{fqdn}, status code: #{response_double.code}, response body: #{response_double.body}")
              end
            end

            context 'when there was an error connecting to the slack webhook endpoint' do
              context 'when the endpoint is an invalid domain' do
                let(:http_error_response) { 'Failed to open TCP connection to :80 (Connection refused - connect(2) for nil port 80' }
                let(:slack_webhook_url) { 'invalid-domain.com' }

                it 'will catch the exception raised by SlackNotifier#notify' do
                  allow(Rails.logger).to receive(:info)
                  allow_any_instance_of(Domain).to receive(:certificate_expiring?).and_return(true)
                  allow_any_instance_of(Domain).to receive(:certificate_expiring?).and_return(true)
                  allow_any_instance_of(Domain).to receive(:certificate_expiring_not_before).and_return(cert_not_before)
                  allow(Figaro).to receive_message_chain(:env, :send_expiry_notifications_to_slack).and_return(true)
                  allow(Figaro).to receive_message_chain(:env, :slack_webhook_url).and_return(slack_webhook_url)
                  allow_any_instance_of(SlackNotifier).to receive(:notify).with(message).
                    and_raise(Errno::ECONNREFUSED, http_error_response)

                  expect { CheckCertificateJob.perform_now }.not_to raise_error
                  expect(Rails.logger).not_to have_received(:info).
                    with("Expiry notification successfully sent to slack for domain #{fqdn}")
                end
              end
            end
          end

          context 'when slack_webhook_url_is empty' do
            let(:slack_webhook_url) { '' }

            it 'will not call SlackNotifier#notify' do
              allow_any_instance_of(Domain).to receive(:certificate_expiring?).and_return(true)
              allow(Figaro).to receive_message_chain(:env, :send_expiry_notifications_to_slack).and_return(true)
              allow(Figaro).to receive_message_chain(:env, :slack_webhook_url).and_return(slack_webhook_url)
              expect_any_instance_of(SlackNotifier).not_to receive(:notify).with(anything)

              CheckCertificateJob.perform_now
            end
          end
        end
      end
    end
  end
end
