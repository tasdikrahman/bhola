# frozen_string_literal: true

class Domain < ApplicationRecord
  validates :fqdn, presence: true, uniqueness: true

  def certificate_expiring?
    ctx = OpenSSL::SSL::SSLContext.new
    begin
      socket = TCPSocket.new(fqdn, 443)
      ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ctx)
      ssl_socket.connect
      ssl_certificate = ssl_socket.peer_cert

      self.certificate_expiring_not_before = ssl_certificate.not_before
      self.certificate_expiring_not_after = ssl_certificate.not_after
      self.issuer = ssl_certificate.issuer

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
end
