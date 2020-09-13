# frozen_string_literal: true

require './config/boot'
require './config/environment'

# Clockwork module triggers CheckCertificateJob.method to trigger certificate_expiring? on all the stored domains
module Clockwork
  every(Figaro.env.check_certificate_job_retrigger_threshold.to_i.second, 'check_certificate_job.perform_now') do
    CheckCertificateJob.perform_now
  end
end
