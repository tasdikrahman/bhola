module Api
  module V1
    class DomainsController < ApplicationController
      skip_before_action :verify_authenticity_token

      def create
        fqdn = params.require(:fqdn)
        domain = Domain.create(fqdn: fqdn)
        render :json => {:data => { 'fqdn': fqdn }, :errors => []}, status: :created
      end
    end
  end
end
