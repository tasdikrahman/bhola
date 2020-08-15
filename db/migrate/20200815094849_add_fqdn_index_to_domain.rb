class AddFqdnIndexToDomain < ActiveRecord::Migration[6.0]
  def change
    add_index :domains, :fqdn, :unique => true
  end
end
