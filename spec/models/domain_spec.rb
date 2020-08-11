require 'rails_helper'

RSpec.describe Domain, type: :model do
  it { expect(described_class).to be < ApplicationRecord }
end
