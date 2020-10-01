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

        context 'when send_expiry_notifications_to_slack env var is set to true' do
          context 'when slack_webhook_url is not empty' do
            let(:cert_not_before) { Time.parse('2012-10-1 8:00:00 Pacific Time (US & Canada)').utc }
            let(:message) { "Your #{fqdn} is expiring at #{cert_not_before}, please renew your cert" }
            let(:slack_webhook_url) { 'foo.slackwebhook.com/bar/webhook' }

            it 'will call SlackNotifier#notify' do
              allow_any_instance_of(Domain).to receive(:certificate_expiring?).and_return(true)
              allow_any_instance_of(Domain).to receive(:certificate_expiring_not_before).and_return(cert_not_before)
              allow(Figaro).to receive_message_chain(:env, :send_expiry_notifications_to_slack).and_return(true)
              allow(Figaro).to receive_message_chain(:env, :slack_webhook_url).and_return(slack_webhook_url)
              expect_any_instance_of(SlackNotifier).to receive(:notify).with(message).once

              CheckCertificateJob.perform_now
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
