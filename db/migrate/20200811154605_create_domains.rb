# frozen_string_literal: true

class CreateDomains < ActiveRecord::Migration[6.0]
  def change
    create_table :domains do |t|
      t.string 'fqdn', null: false
      t.boolean 'certificate_expiring'

      t.timestamps
    end
  end
end
