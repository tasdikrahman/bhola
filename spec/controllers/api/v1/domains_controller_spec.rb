# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::DomainsController, type: :controller do
  describe 'POST #create' do
    context 'when the user sends a domain to be tracked' do
      let(:input_fqdn) { 'https://foo.example.com' }
      let(:trimmed_fqdn) { 'foo.example.com' }
      let(:params) do
        {
          'fqdn' => input_fqdn
        }
      end

      context 'and it doesn\'t exist in the db' do
        let(:cert_not_before) { Time.parse('2012-10-1 8:00:00 Pacific Time (US & Canada)').utc }
        let(:cert_not_after) { Time.parse('2030-10-1 8:00:00 Pacific Time (US & Canada)').utc }
        let(:expected_response) do
          {
            'data' => {
              'fqdn' => trimmed_fqdn,
              'certificate_expiring' => false,
              'certificate_issued_at' => cert_not_before,
              'certificate_expiring_at' => cert_not_after,
              'certificate_issuer' => 'Foo Inc'
            },
            'errors' => []
          }.to_json
        end

        it 'persists the fqdn in the db' do
          allow_any_instance_of(Domain).to receive(:valid?).and_return(true)
          allow_any_instance_of(Domain).to receive(:certificate_expiring?).and_return(false)
          allow_any_instance_of(Domain).to receive_message_chain(:errors, :any?).and_return(nil)
          allow_any_instance_of(Domain).to receive(:certificate_expiring).and_return(false)
          allow_any_instance_of(Domain).to receive(:certificate_expiring_not_after).and_return(cert_not_after)
          allow_any_instance_of(Domain).to receive(:certificate_expiring_not_before).and_return(cert_not_before)
          allow_any_instance_of(Domain).to receive(:certificate_issuer).and_return('Foo Inc')

          post :create, :params => params

          expect(response).to have_http_status(201)
          expect(response.content_type).to eq('application/json; charset=utf-8')
          expect(response.body).to eq(expected_response)
          expect(Domain.where(fqdn: trimmed_fqdn).count).to eq(1)
        end

        it 'also calls Domain#check_certificate?' do
          expect_any_instance_of(Domain).to receive(:certificate_expiring?)

          post :create, :params => params
        end

        it 'also calls Domain#set_url_scheme to trim http/https scheme' do
          expect_any_instance_of(Domain).to receive(:set_url_scheme)

          post :create, :params => params
        end
      end

      context 'and it already is being tracked' do
        let(:expected_response) do
          {
            'data' => {
              'fqdn' => trimmed_fqdn
            },
            'errors' => ["#{trimmed_fqdn} is already being tracked"]
          }.to_json
        end

        it 'returns back the uniqueness validation error message' do
          Domain.create!(fqdn: trimmed_fqdn)

          post :create, :params => params

          expect(response).to have_http_status(422)
          expect(response.content_type).to eq('application/json; charset=utf-8')
          expect(response.body).to eq(expected_response)
          expect(Domain.all.count).to eq(1)
        end
      end

      context 'Domain.check_certificate? has errors' do
        let(:error_message) { '{:socket_error=>[{:message=>"getaddrinfo: Name or service not known"}]}' }
        let(:expected_response) do
          {
            'data' => {
              'fqdn' => trimmed_fqdn
            },
            'errors' => ["#{trimmed_fqdn} is invalid, error message: #{error_message}"]
          }.to_json
        end

        it 'will not persist the fqdn to domains table' do
          post :create, :params => params

          expect(response).to have_http_status(422)
          expect(response.content_type).to eq('application/json; charset=utf-8')
          expect(response.body).to eq(expected_response)
          expect(Domain.where(fqdn: trimmed_fqdn).count).to eq(0)
        end
      end
    end
  end

  describe 'GET #index' do
    context 'format json' do
      context 'user requests for a domain resource' do
        let(:input_fqdn_1) { 'foo.example.com' }
        let(:input_fqdn_2) { 'bar.example.com' }

        before(:each) do
          request.headers['Accept'] = 'application/json'
        end

        context 'there are domains being tracked' do
          let(:cert_not_before) { Time.parse('2012-10-1 8:00:00 Pacific Time (US & Canada)').utc }
          let(:cert_not_after) { Time.parse('2030-10-1 8:00:00 Pacific Time (US & Canada)').utc }
          let!(:domain1) do
            Domain.create(
              fqdn: input_fqdn_1,
              certificate_expiring: false,
              certificate_expiring_not_after: cert_not_after,
              certificate_expiring_not_before: cert_not_before,
              certificate_issuer: 'foo'
            )
          end
          let!(:domain2) do
            Domain.create(
              fqdn: input_fqdn_2,
              certificate_expiring: false,
              certificate_expiring_not_after: cert_not_after,
              certificate_expiring_not_before: cert_not_before,
              certificate_issuer: 'foo'
            )
          end
          let(:expected_response) do
            {
              'data' => [
                {
                  'fqdn' => domain1.fqdn,
                  'certificate_expiring' => domain1.certificate_expiring,
                  'certificate_issued_at' => domain1.certificate_expiring_not_after,
                  'certificate_expiring_at' => domain1.certificate_expiring_not_before,
                  'certificate_issuer' => domain1.certificate_issuer
                },
                {
                  'fqdn' => domain2.fqdn,
                  'certificate_expiring' => domain2.certificate_expiring,
                  'certificate_issued_at' => domain2.certificate_expiring_not_after,
                  'certificate_expiring_at' => domain2.certificate_expiring_not_before,
                  'certificate_issuer' => domain2.certificate_issuer
                }
              ],
              'errors' => []
            }.to_json
          end

          it 'returns back the domains and other fields' do
            get :index

            expect(response).to have_http_status(200)
            expect(response.content_type).to eq('application/json; charset=utf-8')
            expect(response.body['data']).to eq(expected_response['data'])
            expect(response.body['errors']).to eq(expected_response['errors'])
          end
        end

        context 'there are no domains being tracked' do
          let(:expected_response) do
            {
              'data' => [],
              'errors' => []
            }.to_json
          end

          it 'returns back empty data' do
            get :index

            expect(response).to have_http_status(200)
            expect(response.content_type).to eq('application/json; charset=utf-8')
            expect(response.body).to eq(expected_response)
          end
        end
      end
    end

    context 'format html' do
      before(:each) do
        request.headers['Accept'] = 'text/html'
      end

      it 'will have the response content type of text/html' do
        get :index

        expect(response).to have_http_status(200)
        expect(response.content_type).to eq('text/html; charset=utf-8')
      end
    end
  end

  context 'routing' do
    it 'will route GET / to api/v1/domains#index' do
      expect(get: '/').to route_to(controller: 'api/v1/domains', action: 'index')
    end

    it 'will route GET /api/v1/domains to api/v1/domains#index' do
      expect(get: 'api/v1/domains').to route_to(controller: 'api/v1/domains', action: 'index')
    end

    it 'will route POST /api/v1/domains to api/v1/domains#create' do
      expect(post: 'api/v1/domains').to route_to(controller: 'api/v1/domains', action: 'create')
    end
  end
end
