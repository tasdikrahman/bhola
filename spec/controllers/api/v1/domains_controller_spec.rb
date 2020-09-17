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
        let(:expected_response) do
          {
            'data' => {
              'fqdn' => trimmed_fqdn
            },
            'errors' => []
          }.to_json
        end

        it 'persists the fqdn in the db' do
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
          let!(:domain1) { Domain.create(fqdn: input_fqdn_1) }
          let!(:domain2) { Domain.create(fqdn: input_fqdn_2) }
          let(:expected_response) do
            {
              'data' => [
                {
                  'fqdn' => input_fqdn_1,
                  'certificate_expiring' => false
                },
                {
                  'fqdn' => input_fqdn_2,
                  'certificate_expiring' => false
                }
              ],
              'errors' => []
            }.to_json
          end

          it 'returns back the domains and it\'s fqdn and certificate_expiring field' do
            get :index

            expect(response).to have_http_status(200)
            expect(response.content_type).to eq('application/json; charset=utf-8')
            expect(response.body).to eq(expected_response)
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
