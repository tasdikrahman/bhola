class Domain < ApplicationRecord
  validates :fqdn, presence: true, uniqueness: true

  def check_certificate
    ctx = OpenSSL::SSL::SSLContext.new
    socket = TCPSocket.new(self.fqdn, 443)
    ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ctx)
    ssl_socket.connect
    ssl_certificate = ssl_socket.peer_cert
    self.certificate_expiring = true unless ssl_certificate.not_after < Time.now.utc
  end
end
