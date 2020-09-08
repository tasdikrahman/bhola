# frozen_string_literal: true

class Domain < ApplicationRecord
  validates :fqdn, presence: true, uniqueness: true

  def check_certificate
    ctx = OpenSSL::SSL::SSLContext.new
    begin
      socket = TCPSocket.new(fqdn, 443)
    rescue SocketError => e
      Rails.logger.error("Error connecting to #{fqdn}, error: #{e}")
      return
    end
    ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ctx)
    ssl_socket.connect
    ssl_certificate = ssl_socket.peer_cert
    if ssl_certificate.not_after < (Time.now.utc + Figaro.env.certificate_expiry_threshold.to_i.days)
      self.certificate_expiring = true
      save
    end
  end
end
