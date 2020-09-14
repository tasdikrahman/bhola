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
          render :json => { :data => { 'fqdn': fqdn }, :errors => [] }, :status => :created
        else
          render :json => { :data => { 'fqdn': fqdn }, :errors => ["#{fqdn} is already being tracked"] },
                 :status => :unprocessable_entity
        end
      end

      def index
        if Domain.any?
          domain_list = []
          @domains = Domain.all
          @domains.each do |domain|
            domain_list = Array(domain_list).push(
              {
                'fqdn': domain.fqdn,
                'certificate_expiring': domain.certificate_expiring
              }
            )
          end
          respond_to do |format|
            format.html { @domains }
            format.json { render :json => { :data => domain_list, :errors => [] }, :status => :ok }
          end
        else
          respond_to do |format|
            format.html { @domains }
            format.json { render :json => { :data => [], :errors => [] }, :status => :ok }
          end
        end
      end
    end
  end
end
