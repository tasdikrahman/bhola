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
            'errors' => ['domain already is already being tracked']
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
      let(:input_fqdn) { 'foo.example.com' }

      context 'the id exists' do
        let!(:domain) { Domain.create(fqdn: input_fqdn) }
        let(:expected_response) do
          {
            'data' => {
              'fqdn' => input_fqdn,
              'certificate_expiring' => false
            },
            'errors' => []
          }.to_json
        end

        it 'returns back the fqdn associated with that id' do
          get :show, params: { id: domain.id }

          expect(response).to have_http_status(200)
          expect(response.content_type).to eq('application/json; charset=utf-8')
          expect(response.body).to eq(expected_response)
        end
      end

      context 'the id doesn\'t exists' do
        let(:input_id) { 1 }
        let(:expected_response) do
          {
            'data' => [],
            'errors' => ["requested id: #{input_id} doesn't exist"]
          }.to_json
        end

        it 'returns back the error message that the id doesn\'t exist' do
          get :show, params: { id: input_id }

          expect(response).to have_http_status(404)
          expect(response.content_type).to eq('application/json; charset=utf-8')
          expect(response.body).to eq(expected_response)
        end
      end
    end
  end
end
