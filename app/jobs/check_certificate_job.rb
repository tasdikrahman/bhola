# frozen_string_literal: true

# CheckCertificateJob will iterate over all the Domain objects stored and call the method #check_certificate on it
class CheckCertificateJob < ApplicationJob
  def perform(*)
    Rails.logger.info('No domains are tracked as of now, please insert domains to be tracked') if Domain.all.count.zero?
  end
end
