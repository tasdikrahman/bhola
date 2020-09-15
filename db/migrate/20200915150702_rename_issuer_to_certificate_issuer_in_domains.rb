# frozen_string_literal: true

# Renames issuer to certificate_issuer, for being more explicit
class RenameIssuerToCertificateIssuerInDomains < ActiveRecord::Migration[6.0]
  def change
    rename_column :domains, :issuer, :certificate_issuer
  end
end
