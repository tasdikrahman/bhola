class Domain < ApplicationRecord
  validates :fqdn, presence: true, uniqueness: true
end
