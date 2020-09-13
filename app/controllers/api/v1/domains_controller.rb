# frozen_string_literal: true

module Api
  module V1
    class DomainsController < ApplicationController
      skip_before_action :verify_authenticity_token

      def create
        fqdn = params.require(:fqdn)

        domain = Domain.new(fqdn: fqdn)
        if domain.valid?
          domain.save!
          render :json => { :data => { 'fqdn': fqdn }, :errors => [] }, :status => :created and return
        end
        render :json => { :data => { 'fqdn': fqdn }, :errors => ['domain already is already being tracked'] },
               :status => :unprocessable_entity and return
      end

      def index
        if Domain.any?
          domain_list = []
          Domain.all.each do |domain|
            domain_list = Array(domain_list).push(
              {
                'fqdn': domain.fqdn,
                'certificate_expiring': domain.certificate_expiring
              }
            )
          end
          render :json => { :data => domain_list,
                            :errors => [] }, :status => :ok and return
        end
        render :json => { :data => [],
                          :errors => [] }, :status => :ok
      end
    end
  end
end
