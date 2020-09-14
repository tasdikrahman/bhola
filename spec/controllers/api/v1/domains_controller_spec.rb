# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::DomainsController, type: :controller do
  describe 'POST #create' do
    context 'when the user sends a domain to be tracked' do
      let(:input_fqdn) { 'foo.example.com' }
      let(:params) do
        {
          'fqdn' => input_fqdn
        }
      end

      context 'and it doesn\'t exist in the db' do
        let(:expected_response) do
          {
            'data' => {
              'fqdn' => input_fqdn
            },
            'errors' => []
          }.to_json
        end

        it 'persists the fqdn in the db' do
          post :create, :params => params

          expect(response).to have_http_status(201)
          expect(response.content_type).to eq('application/json; charset=utf-8')
          expect(response.body).to eq(expected_response)
          expect(Domain.where(fqdn: input_fqdn).count).to eq(1)
        end
      end

      context 'and it already is being tracked' do
        let(:expected_response) do
          {
            'data' => {
              'fqdn' => input_fqdn
            },
            'errors' => ["#{input_fqdn} is already being tracked"]
          }.to_json
        end

        it 'returns back the uniqueness validation error message' do
          Domain.create!(fqdn: input_fqdn)

          post :create, :params => params

          expect(response).to have_http_status(422)
          expect(response.content_type).to eq('application/json; charset=utf-8')
          expect(response.body).to eq(expected_response)
          expect(Domain.all.count).to eq(1)
        end
      end
    end
  end

  describe 'GET #show' do
    context 'user requests for a domain resource' do
      let(:input_fqdn_1) { 'foo.example.com' }
      let(:input_fqdn_2) { 'bar.example.com' }

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
end
