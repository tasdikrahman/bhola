# frozen_string_literal: true

# CheckCertificateJob will iterate over all the Domain objects stored and call the method #check_certificate on it
class CheckCertificateJob < ApplicationJob
  def perform(*args)
    if Domain.all.count.zero?
      Rails.logger.info('No domains are tracked as of now, please insert domains to be tracked')
      return
    end
    domains = Domain.all
    domains.each do |domain|
      if domain.certificate_expiring?
        Rails.logger.info("#{domain.fqdn} is expiring within the buffer period")
      else
        Rails.logger.info("#{domain.fqdn} is not expiring within the buffer period")
      end
    end
  end
end
