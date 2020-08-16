require 'rails_helper'

RSpec.describe Domain, type: :model do
  it { expect(described_class).to be < ApplicationRecord }

  it 'is not valid without an fqdn present' do
    domain = Domain.new(fqdn: nil)

    expect(domain.save).to be_falsey
    expect(domain).not_to be_valid
    expect(Domain.all.count).to eq(0)
  end

  it 'has certificate_expiring set to false when saving model object' do
    domain = Domain.create(fqdn: 'foo.example.com')

    expect(domain.certificate_expiring).to be_falsey
    expect(Domain.all.count).to eq(1)
  end

  it 'has a uniqueness check on the fqdn when trying to create persist object' do
    fqdn = 'foo.example.com'
    Domain.create!(fqdn: fqdn)
    domain2 = Domain.new(fqdn: fqdn)

    expect(domain2).to_not be_valid
    expect(domain2.errors[:fqdn]).to include("has already been taken")
    expect(Domain.all.count).to eq(1)
  end
end
