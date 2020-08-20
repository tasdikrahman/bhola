class Domain < ApplicationRecord
  validates :fqdn, presence: true, uniqueness: true

  def check_certificate
    ctx = OpenSSL::SSL::SSLContext.new
    socket = TCPSocket.new(self.fqdn, 443)
  end
end
