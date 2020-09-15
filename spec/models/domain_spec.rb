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

  context '#certificate_expiring?' do
    context 'domain inserted is registered' do
      let(:fqdn) { 'example.com' }
      let(:domain) { Domain.create(fqdn: fqdn) }
      let(:port) { 443 }

      context 'connection is successfull' do
        let(:cert_name) do
          OpenSSL::X509::Name.new [['CN', 'www.github.com'], ['O', 'Github\, Inc.'], ['L', 'San Francisco'],
                                   %w[ST California], %w[C US]]
        end
        let(:cert_issuer) do
          OpenSSL::X509::Name.new [['CN', 'DigiCert SHA2 High Assurance Server CA'], ['O', 'DigiCert Inc'],
                                   ['OU', 'www.digicert.com'], %w[C US]]
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
          cert.issuer = cert_issuer
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

          it 'returns false and does nothing to the certificate_expiring field' do
            got = domain.certificate_expiring?

            expect(got).to be false
            expect(Domain.find_by(fqdn: fqdn).certificate_expiring).to be false
          end
        end

        context 'the certificate is about to expire within the buffer period set' do
          let(:cert_not_after) { Time.parse('2020-6-10 8:00:00 Pacific Time (US & Canada)').utc }

          it 'returns true and updates the certificate_expiring field to be true' do
            got = domain.certificate_expiring?

            expect(got).to be true
            expect(Domain.find_by(fqdn: fqdn).certificate_expiring).to be true
          end
        end

        context 'additional metadata' do
          let(:cert_not_after) { Time.parse('2020-6-10 8:00:00 Pacific Time (US & Canada)').utc }

          it 'will store not_before information for the domain' do
            domain.certificate_expiring?

            expect(Domain.find_by(fqdn: fqdn).certificate_expiring_not_before).to eq(cert_not_before)
          end

          it 'will store not_after information for the domain' do
            domain.certificate_expiring?

            expect(Domain.find_by(fqdn: fqdn).certificate_expiring_not_after).to eq(cert_not_after)
          end

          it 'will store certificate issuer information for the domain' do
            domain.certificate_expiring?

            expect(Domain.find_by(fqdn: fqdn).certificate_issuer).to eq(cert_issuer.to_s)
          end
        end
      end

      context 'connection in un-successfull' do
        context 'domain doesn\'t have an ssl cert attached' do
          let(:error_message) { 'SSL_connect returned=1 errno=0 state=error: sslv3 alert handshake failure' }

          it 'logs a SSLError with sslv3 handshake failure' do
            tcpsocket_double = double(TCPSocket)
            sslcontext_double = double(OpenSSL::SSL::SSLContext)
            sslsocket_double = double(OpenSSL::SSL::SSLSocket)
            expect(OpenSSL::SSL::SSLContext).to receive(:new).and_return(sslcontext_double)
            expect(TCPSocket).to receive(:new).with(domain.fqdn, port).and_return(tcpsocket_double)
            expect(OpenSSL::SSL::SSLSocket).to receive(:new).with(tcpsocket_double, sslcontext_double).
              and_return(sslsocket_double)

            allow(sslsocket_double).to receive(:connect).and_raise(OpenSSL::SSL::SSLError, error_message)
            allow(Rails.logger).to receive(:error)

            domain.certificate_expiring?

            expect(Rails.logger).to have_received(:error).
              with("error: #{error_message}, does fqdn: #{fqdn} even having a cert attached?")
            expect(domain.errors.full_messages).to eq(["Sslv3 error {:message=>\"#{error_message}\"}"])
          end
        end
      end
    end

    context 'domain inserted is not registered' do
      let(:port) { 443 }
      let(:fqdn) { 'invalid-domain.com' }
      let(:domain) { Domain.create(fqdn: fqdn) }
      let(:error_message) { 'getaddrinfo: Name or service not known' }

      it 'logs a SocketError with getaddrinfo' do
        allow(TCPSocket).to receive(:new).with(fqdn, port).and_raise(SocketError, error_message)
        allow(Rails.logger).to receive(:error)

        domain.certificate_expiring?

        expect(Rails.logger).to have_received(:error).with("Error connecting to #{fqdn}, error: #{error_message}")
        expect(domain.errors.full_messages).to eq(["Socket error {:message=>\"#{error_message}\"}"])
      end
    end
  end

  context '#cert_issuer_to_s' do
    let(:cert_issuer) do
      OpenSSL::X509::Name.new [['CN', 'DigiCert SHA2 High Assurance Server CA'], ['O', 'DigiCert Inc'],
                               ['OU', 'www.digicert.com'], %w[C US]]
    end
    let(:domain) { Domain.create(fqdn: fqdn) }
    let(:fqdn) { 'invalid-domain.com' }

    before(:each) do
      domain.certificate_issuer = cert_issuer
    end

    it 'will return back the issuer\'s organisation name' do
      got = domain.cert_issuer_to_s

      expect(got).to eq('DigiCert Inc')
    end

    context 'when it doesn\'t have the key O in the issuer name' do
      let(:cert_issuer) do
        OpenSSL::X509::Name.new [['CN', 'invalid2.invalid'],
                                 ['OU', 'No SNI provided; please fix your client']]
      end
      it 'will return back the complete issuer string back' do
        got = domain.cert_issuer_to_s

        expect(got).to eq(cert_issuer.to_s)
      end
    end
  end
end
