# Copyright 2013 SAP AG.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http: //www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an 
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
# either express or implied. See the License for the specific 
# language governing permissions and limitations under the License.

require 'spec_helper'

describe V2::ServiceBindingsController do
  let(:db_settings) { Rails.configuration.database_configuration[Rails.env] }
  let(:admin_user) { db_settings.fetch('username') }
  let(:admin_password) { db_settings.fetch('password') }
  let(:database_host) { db_settings.fetch('host') }
  let(:database_port) { db_settings.fetch('port') }
  let(:dsn) { db_settings.fetch('dsn') }

  let(:instance_id) { 'instance-1' }
  let(:instance) { ServiceInstance.new(id: instance_id) }

  before do
    authenticate
    instance.save
  end

  after do
    instance.destroy
  end

  describe '#update' do
    let(:binding_id) { '123' }
    let(:generated_dbname) { ServiceInstance.new(id: instance_id).database }

    let(:generated_username) { ServiceBinding.new(id: binding_id).username }

    before do
    end
    
    after do
      ServiceBinding.new(id: binding_id, service_instance: instance).destroy
    end
    
    it 'grants permission to access the given database' do
      expect(ServiceBinding.exists?(id: binding_id, service_instance_id: instance_id)).to eq(false)        
      put :update, id: binding_id, service_instance_id: instance_id
      expect(ServiceBinding.exists?(id: binding_id, service_instance_id: instance_id)).to eq(true)
    end

    it 'responds with generated credentials' do
      put :update, id: binding_id, service_instance_id: instance_id

      binding = JSON.parse(response.body)
      username = binding['credentials']['username'];
      password = binding['credentials']['password'];
      ServiceInstance.rdbi_connection_ex(dsn,username,password);        
      expect(binding['credentials']['hostname']).to eq(database_host)
      expect(binding['credentials']['port']).to eq(database_port)
      expect(binding['credentials']['username']).to eq(generated_username)
      expect(binding['credentials']['password']).to eq(password)        
      expect(binding['credentials']['dsn']).to eq(dsn)
      expect(binding['credentials']['jdbcUrl']).to eq(
        "jdbc:sap://#{username}:#{password}@#{database_host}:#{database_port}/#{generated_dbname}?currentschema=#{generated_dbname}")
      expect(binding['credentials']['uri']).to eq(
        "sap://#{username}:#{password}@#{database_host}:#{database_port}/#{generated_dbname}?currentschema=#{generated_dbname}")
    end
 
    it 'returns a 201' do
      put :update, id: binding_id, service_instance_id: instance_id
      expect(response.status).to eq(201)
    end
  end

  describe '#destroy' do
    let(:binding_id) { 'BINDING-1' }
    let(:binding) { ServiceBinding.new(id: binding_id, service_instance: instance) }
    let(:username) { binding.username }

    context 'when the user exists' do
      before do
        binding.save
      end
      after do
        binding.destroy 
     end

      it 'destroys the user' do
        expect(ServiceBinding.exists?(id: binding.id, service_instance_id: instance.id)).to eq(true)

        delete :destroy, service_instance_id: instance.id, id: binding.id

        expect(ServiceBinding.exists?(id: binding.id, service_instance_id: instance.id)).to eq(false)
      end

      it 'returns a 204' do
        delete :destroy, service_instance_id: instance.id, id: binding.id

        expect(response.status).to eq(204)
      end
    end

    context 'when the user does not exist' do      
      it 'returns a 410' do
        delete :destroy, service_instance_id: instance.id, id: binding.id
        expect(response.status).to eq(410)
      end
    end
  end
end
