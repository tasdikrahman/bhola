require 'rails_helper'

RSpec.describe Api::V1::DomainsController, type: :controller do
  describe 'POST #create' do
    context 'when the domain passed does not exist inside the database' do
      let(:input_fqdn) { 'foo.example.com' }
      let(:params) do
        {
            'fqdn' => input_fqdn
        }
      end
      let(:expected_response) do
        {
            'data' => {
                'fqdn' => input_fqdn
            },
            'errors' => []
        }.to_json
      end

      it 'saves the domain in the db' do
        post :create, :params => params

        expect(response).to have_http_status(201)
        expect(response.content_type).to eq('application/json; charset=utf-8')
        expect(response.body).to eq(expected_response)
        expect(Domain.where(fqdn: input_fqdn).count).to eq(1)
      end
    end
  end
end