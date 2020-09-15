# frozen_string_literal: true

# Adds columns not_before, not_after and issuer in the domains table, for each domain
class AddNotBeforeNotAfterIssuerToDomains < ActiveRecord::Migration[6.0]
  def change
    change_table :domains, :bulk => true do |t|
      # stores the issue date of the cert
      t.datetime :certificate_expiring_not_after
      # stores the expiry date of the cert
      t.datetime :certificate_expiring_not_before
      t.string :issuer
    end
  end
end
