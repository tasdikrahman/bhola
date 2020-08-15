require 'rails_helper'

RSpec.describe Domain, type: :model do
  it { expect(described_class).to be < ApplicationRecord }

  it 'is not valid without an fqdn present' do
    domain = Domain.new(fqdn: nil)
    expect(domain).not_to be_valid
  end

  it 'has certificate_expiring set to false when saving model object' do
    domain = Domain.create(fqdn: 'foo.example.com')
    expect(domain.certificate_expiring).to be_falsey
  end
end
