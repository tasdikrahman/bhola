class Domain < ApplicationRecord
  validates :fqdn, presence: true, uniqueness: true

  def check_certificate
    ctx = OpenSSL::SSL::SSLContext.new
  end
end
