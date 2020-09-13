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
      context 'when the domain tracked is not expiring within the buffer timezone' do
        let(:fqdn) { 'foo.example.com' }
        let!(:domain) { Domain.create(fqdn: fqdn) }

        it 'will log via rails logger that no tracked domains are expiring within the buffer period' do
          allow(Rails.logger).to receive(:info)
          allow_any_instance_of(Domain).to receive(:certificate_expiring?).and_return(false)

          CheckCertificateJob.perform_now

          expect(Rails.logger).to have_received(:info).
            with("#{fqdn} is not expiring within the buffer period")
        end
      end
    end
  end
end
