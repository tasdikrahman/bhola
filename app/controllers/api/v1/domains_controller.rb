# frozen_string_literal: true

module Api
  module V1
    class DomainsController < ApplicationController
      skip_before_action :verify_authenticity_token

      def create
        fqdn = params.require(:fqdn)

        domain = Domain.new(fqdn: fqdn)
        domain.set_url_scheme
        if domain.valid?
          domain.certificate_expiring?
          if domain.errors.any?
            render :json => { :data => { 'fqdn': domain.fqdn },
                              :errors => ["#{domain.fqdn} is invalid, error message: #{domain.errors.messages}"] },
                   :status => :unprocessable_entity
          else
            domain.save!
            render :json => { :data => { 'fqdn': domain.fqdn }, :errors => [] }, :status => :created
          end
        else
          render :json => { :data => { 'fqdn': domain.fqdn }, :errors => ["#{domain.fqdn} is already being tracked"] },
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
