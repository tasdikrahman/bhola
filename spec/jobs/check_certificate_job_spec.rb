require 'rails_helper'

RSpec.describe CheckCertificateJob, type: :job do
  it { expect(described_class).to be < ApplicationJob }
end
