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

describe ServiceBinding do
  let(:id) { 'fa790aea-ab7f-41e8-b6f9-a2a1d60403f5' }
  let(:binding) { ServiceBinding.new(id: id, service_instance: instance) }

  let(:instance_id) { '88f6fa22-c8b7-4cdc-be3a-dc09ea7734db' }
  let(:instance) { ServiceInstance.new(id: instance_id) }
  let(:database) { instance.database }
  let(:username) { binding.username }
  let(:password) { binding.password }


  after do
    ServiceInstance.rdbi_drop_user(username)
  end

  describe '.find_by_id' do
    context 'when the user exists' do
      before do
        ServiceInstance.rdbi_create_user(username,password);
      end
      it 'returns the binding' do
        binding = ServiceBinding.find_by_id(id)
        expect(binding).to be_a(ServiceBinding)
        expect(binding.id).to eq(id)
      end
    end

    context 'when the user does not exist' do
      it 'returns nil' do
        binding = ServiceBinding.find_by_id(id)
        expect(binding).to be_nil
      end
    end
  end

  describe '.find_by_id_and_service_instance_id' do
    context 'when the user exists and has all privileges' do
      before do
        ServiceInstance.rdbi_create_user(username, password)
        ServiceInstance.rdbi_create_database_if_not_exists(database)
        ServiceInstance.rdbi_grant_full_access_to_user(username, database)
      end

      it 'returns the binding' do
        binding = ServiceBinding.find_by_id_and_service_instance_id(id, instance_id)
        expect(binding).to be_a(ServiceBinding)
        expect(binding.id).to eq(id)
      end
    end

    context 'when the user exists but does not have all privileges' do
      before do
        ServiceInstance.rdbi_create_user(username, password)
      end
      it 'returns nil' do
        binding = ServiceBinding.find_by_id_and_service_instance_id(id, instance_id)
        expect(binding).to be_nil
      end
    end

    context 'when the user does not exist' do
      it 'returns nil' do
        binding = ServiceBinding.find_by_id_and_service_instance_id(id, instance_id)
        expect(binding).to be_nil
      end
    end
  end

  describe '.exists?' do
    context 'when the user exists and has all privileges' do
      before do
        ServiceInstance.rdbi_create_user(username, password)
        ServiceInstance.rdbi_create_database_if_not_exists(database)
        ServiceInstance.rdbi_grant_full_access_to_user(username, database)
      end
      it 'returns true' do
        expect(ServiceBinding.exists?(id: id, service_instance_id: instance_id)).to eq(true)
      end
    end

    context 'when the user exists but does not have all privileges' do
      before do
        ServiceInstance.rdbi_create_user(username, password)
      end
      it 'returns false' do
        expect(ServiceBinding.exists?(id: id, service_instance_id: instance_id)).to eq(false)
      end
    end

    context 'when the user does not exist' do
      it 'returns false' do
        expect(ServiceBinding.exists?(id: id, service_instance_id: instance_id)).to eq(false)
      end
    end
  end

  describe '#username' do
    it 'returns the same username for a given id' do
      binding1 = ServiceBinding.new(id: 'some_id')
      binding2 = ServiceBinding.new(id: 'some_id')
      expect(binding1.username).to eq(binding2.username)
    end

    it 'returns different usernames for different ids' do
      binding1 = ServiceBinding.new(id: 'some_id')
      binding2 = ServiceBinding.new(id: 'some_other_id')
      expect(binding2.username).to_not eq(binding1.username)
    end

    it 'returns only alphanumeric characters' do
      # HDB doesn't explicitly require this, but we're doing it to be safe
      binding = ServiceBinding.new(id: '~!@#$%^&*()_+{}|:"<>?')
      expect(binding.username).to match(/^[a-zA-Z0-9_]+$/)
    end

    it 'returns no more than 16 characters' do
      # HDB usernames cannot be greater than 16 characters
      binding = ServiceBinding.new(id: 'fa790aea-ab7f-41e8-b6f9-a2a1d60403f5')
      expect(binding.username.length).to be <= 16
    end
  end

  describe '#save' do
    it 'creates a user with a random password' do
      expect {
        binding.save
      }.to change {
        ServiceInstance.rdbi_select_single_value("SELECT DISTINCT COUNT(*) FROM SYS.USERS WHERE USER_NAME = '#{username}'")
      }.from(0).to(1)
    end

    it 'grants the user all privileges for the database' do
      expect {
        ServiceInstance.rdbi_grant_full_access_to_user(username,database)
      }.to raise_error(Exception, /invalid user name/)

      binding.save
    end

    it 'raises an error when creating the same user twice' do
      binding.save
      expect {
        ServiceBinding.new(id: id, service_instance: instance).save
      }.to raise_error
    end
  end

  describe '#destroy' do
    context 'when the user exists' do
      before do
        binding.save
      end

      it 'deletes the user' do
        binding.destroy
        expect {
          ServiceInstance.rdbi_grant_full_access_to_user(username,database)
        }.to raise_error(Exception, /invalid user name/)
      end
    end

    context 'when the user does not exist' do
      it 'does not raise an error' do
        expect {
          ServiceInstance.rdbi_grant_full_access_to_user(username,database)
        }.to raise_error(Exception, /invalid user name/)
        expect {
          binding.destroy
        }.to_not raise_error

        expect {
          ServiceInstance.rdbi_grant_full_access_to_user(username,database)
        }.to raise_error(Exception, /invalid user name/)
      end
    end
  end

  describe '#to_json' do
    let(:connection_config) { Rails.configuration.database_configuration[Rails.env] }
    let(:host) { connection_config.fetch('host') }
    let(:port) { connection_config.fetch('port') }

    before { binding.save }

    it 'includes the credentials' do
      hash = JSON.parse(binding.to_json)
      credentials = hash.fetch('credentials')
      username = credentials.fetch('username');
      password = credentials.fetch('password');
      dsn = credentials.fetch('dsn');      
      ServiceInstance.rdbi_connection_ex(dsn,username,password);         
      expect(credentials.fetch('hostname')).to eq(host)
      expect(credentials.fetch('port')).to eq(port)
      expect(credentials.fetch('name')).to eq(database)
      expect(credentials.fetch('username')).to eq(username)
      expect(credentials.fetch('password')).to eq(password)
      expect(credentials.fetch('uri')).to eq("sap://#{username}:#{password}@#{host}:#{port}/#{database}?currentschema=#{database}")
      expect(credentials.fetch('jdbcUrl')).to eq("jdbc:sap://#{username}:#{password}@#{host}:#{port}/#{database}?currentschema=#{database}")
                        
    end
  end
end
