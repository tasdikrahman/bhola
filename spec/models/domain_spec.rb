# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Domain, type: :model do
  it { expect(described_class).to be < ApplicationRecord }

  it 'is not valid without an fqdn present' do
    domain = Domain.new(fqdn: nil)

    expect(domain.save).to be_falsey
    expect(domain).not_to be_valid
    expect(Domain.all.count).to eq(0)
  end

  it 'has certificate_expiring set to false when saving model object' do
    domain = Domain.create(fqdn: 'foo.example.com')

    expect(domain.certificate_expiring).to be_falsey
    expect(Domain.all.count).to eq(1)
  end

  it 'has a uniqueness check on the fqdn when trying to create persist object' do
    fqdn = 'foo.example.com'
    Domain.create!(fqdn: fqdn)
    domain2 = Domain.new(fqdn: fqdn)

    expect(domain2).to_not be_valid
    expect(domain2.errors[:fqdn]).to include('has already been taken')
    expect(Domain.all.count).to eq(1)
  end

  context '#check_certificate' do
    let(:fqdn) { 'foo.example.com' }
    let(:domain) { Domain.create(fqdn: fqdn) }
    let(:port) { 443 }

    context 'connection is successfull' do
      let(:cert_name) do
        OpenSSL::X509::Name.new [['CN', 'www.github.com'], ['O', 'Github\, Inc.'], ['L', 'San Francisco'],
                                 %w[ST California], %w[C US]]
      end
      let(:cert_not_before) { Time.parse('2012-10-1 8:00:00 Pacific Time (US & Canada)').utc }
      let(:cert) { OpenSSL::X509::Certificate.new }
      let(:threshold_days) { '10' }
      let(:time_now_stub) { Time.parse('2020-6-2 8:00:00 Pacific Time (US & Canada)').utc }

      before(:each) do
        allow(Figaro).to receive_message_chain(:env, :certificate_expiry_threshold).and_return(threshold_days)
        allow(Time).to receive(:now).and_return(time_now_stub)
        cert.subject = cert_name
        cert.not_before = cert_not_before
        cert.not_after = cert_not_after
        tcpsocket_double = double(TCPSocket)
        sslcontext_double = double(OpenSSL::SSL::SSLContext)
        sslsocket_double = double(OpenSSL::SSL::SSLSocket)
        expect(OpenSSL::SSL::SSLContext).to receive(:new).and_return(sslcontext_double)
        expect(TCPSocket).to receive(:new).with(domain.fqdn, port).and_return(tcpsocket_double)
        expect(OpenSSL::SSL::SSLSocket).to receive(:new).with(tcpsocket_double, sslcontext_double).
          and_return(sslsocket_double)
        expect(sslsocket_double).to receive(:connect).and_return(sslsocket_double)
        expect(sslsocket_double).to receive(:peer_cert).and_return(cert)
      end

      context 'the certificate expiry date is outside of the buffer period set' do
        let(:cert_not_after) { Time.parse('2030-10-1 8:00:00 Pacific Time (US & Canada)').utc }

        it 'does nothing to the certificate_expiring field' do
          domain.check_certificate

          expect(Domain.find_by(fqdn: fqdn).certificate_expiring).to be_falsey
        end
      end

      context 'the certificate is about to expire within the buffer period set' do
        let(:cert_not_after) { Time.parse('2020-6-10 8:00:00 Pacific Time (US & Canada)').utc }

        it 'updates the certificate_expiring field to be true' do
          domain.check_certificate

          expect(Domain.find_by(fqdn: fqdn).certificate_expiring).to be_truthy
        end
      end
    end
  end
end
