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
    expect(domain2.errors[:fqdn]).to include("has already been taken")
    expect(Domain.all.count).to eq(1)
  end

  context '#check_certificate' do
    let(:fqdn) { 'foo.example.com' }
    let(:domain) { Domain.create(fqdn: fqdn) }
    let(:port) { 443 }

    context 'connection is successfull' do
      let(:cert_name) {
        OpenSSL::X509::Name.new [['CN', 'www.github.com'], ['O', 'Github\, Inc.'], ['L', 'San Francisco'],
                                 ['ST', 'California'], ['C', 'US']]
      }
      let(:cert_not_before) { Time.parse("2012-10-1 8:00:00 Pacific Time (US & Canada)").utc }
      let(:cert) { OpenSSL::X509::Certificate.new }

      context 'the certificate is valid' do
        let(:cert_not_after) { Time.parse("2030-10-1 8:00:00 Pacific Time (US & Canada)").utc }

        it 'does nothing to the certificate_expiring field' do
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

          domain.check_certificate

          expect(Domain.find_by_fqdn(fqdn).certificate_expiring).to be_falsey
        end
      end

      context 'the certificate has expired' do
        let(:cert_not_after) { Time.parse("2020-6-1 8:00:00 Pacific Time (US & Canada)").utc }

        it 'updates the certificate_expiring field to be true' do
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

          domain.check_certificate

          expect(Domain.find_by_fqdn(fqdn).certificate_expiring).to be_truthy
        end
      end
    end
  end
end
