# frozen_string_literal: true

class AddDefaultValueToCertificateExpiringInDomains < ActiveRecord::Migration[6.0]
  def change
    change_column :domains, :certificate_expiring, :boolean, :default => false
  end
end
