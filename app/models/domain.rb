# frozen_string_literal: true

class Domain < ApplicationRecord
  validates :fqdn, presence: true, uniqueness: true

  CERTIFICATE_ISSUER_ORGANISATION_NAME_METADATA_KEY = 'O'

  def certificate_expiring?
    ctx = OpenSSL::SSL::SSLContext.new
    begin
      socket = TCPSocket.new(fqdn, 443)
      ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ctx)
      ssl_socket.connect
      ssl_certificate = ssl_socket.peer_cert

      self.certificate_expiring_not_before = ssl_certificate.not_before
      self.certificate_expiring_not_after = ssl_certificate.not_after
      self.certificate_issuer = ssl_certificate.issuer

      if ssl_certificate.not_after < (Time.now.utc + Figaro.env.certificate_expiry_threshold.to_i.days)
        self.certificate_expiring = true
        save
        true
      else
        false
      end
    rescue SocketError => e
      Rails.logger.error("Error connecting to #{fqdn}, error: #{e}")
      errors.add(:socket_error, message: e.message.to_s)
    rescue OpenSSL::SSL::SSLError => e
      Rails.logger.error("error: #{e}, does fqdn: #{fqdn} even having a cert attached?")
      errors.add(:sslv3_error, message: e.message.to_s)
    end
  end

  def cert_issuer_to_s
    certificate_metadata_dict = {}
    certificate_issuer_metadata_list = certificate_issuer.split('/')
    certificate_issuer_metadata_list.each do |metadata_element|
      next if metadata_element.blank?
      key = metadata_element.split('=').first
      value = metadata_element.split('=').last
      certificate_metadata_dict[key] = value
    end
    certificate_metadata_dict[CERTIFICATE_ISSUER_ORGANISATION_NAME_METADATA_KEY]
  end
end
