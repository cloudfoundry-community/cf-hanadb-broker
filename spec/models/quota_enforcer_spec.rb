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

describe QuotaEnforcer do
  describe '.enforce!' do
    let(:instance_id) { SecureRandom.uuid }
    let(:instance) { ServiceInstance.new(id: instance_id) }

    let(:binding_id) { SecureRandom.uuid }
    let(:binding) { ServiceBinding.new(id: binding_id, service_instance: instance) }

    let(:max_storage_mb) { Settings.services[0].plans[0].max_storage_mb.to_i }

    before do
      instance.save
      binding.save
    end

    after do
      binding.destroy
      instance.destroy
    end

    context 'for a database that has just moved over its quota' do
      before do
        #client = create_client
        #overflow_database(client)
      end

      it 'revokes insert, update, and create privileges' do
        #QuotaEnforcer.enforce!

        #client = create_client
        #expect {
        #  client.execute("INSERT INTO STUFF (ID, DATA) VALUES (99999, 'This should fail.')").finish()
       	#}.to raise_error(RDBI::Error, /INSERT command denied/)

        #expect {
        #  client.execute("UPDATE STUFF SET DATA = 'This should also fail.' WHERE id = 1").finish()
        #}.to raise_error(RDBI::Error, /UPDATE command denied/)

        #expect {
        #  client.execute('CREATE TABLE MORE_STUFF (ID INT PRIMARY KEY)').finish()
        #}.to raise_error(RDBI::Error, /CREATE command denied/)

        #expect {
        #  client.query('SELECT COUNT(*) FROM STUFF')
        #}.to_not raise_error

        #expect {
        #  client.query('DELETE FROM STUFF WHERE ID = 1')
        #}.to_not raise_error
      end

      it 'kills existing connections' do
        #client = create_client
        #client.query('SELECT 1')

        #QuotaEnforcer.enforce!

        #expect {
        #  client.query('SELECT 1')
        #}.to raise_error(Mysql2::Error, /server has gone away/)
      end

      it 'does not kill root connections' do
        #client = create_root_client
        #client.query('SELECT 1')

        #QuotaEnforcer.enforce!

        #expect {
        #  client.query('SELECT 1')
        #}.to_not raise_error
      end
    end

    context 'for a database that has already moved over its quota' do
      before do
        #client = create_client
        #overflow_database(client)
        #QuotaEnforcer.enforce!
      end

      it 'does not kill existing connections' do
        #client = create_client
        #client.execute('SELECT 1 FROM DUMMY')

        #QuotaEnforcer.enforce!

        #expect {
        #  client.execute('SELECT 1 FROM DUMMY')
        #}.to_not raise_error
      end
    end

    context 'for a database that has just moved under its quota' do
      before do
        #client = create_client
        #overflow_database(client)
        #QuotaEnforcer.enforce!

        #client = create_client
        #prune_database(client)
      end

      it 'grants insert, update, and create privileges' do
        #QuotaEnforcer.enforce!

        #client = create_client
        #expect {
        #  client.query("INSERT INTO stuff (id, data) VALUES (99999, 'This should succeed.')")
        #}.to_not raise_error

        #expect {
        #  client.query("UPDATE stuff SET data = 'This should also succeed.' WHERE id = 99999")
        #}.to_not raise_error

        #expect {
        #  client.query('CREATE TABLE more_stuff (id INT PRIMARY KEY)')
        #}.to_not raise_error

        #expect {
        #  client.query('SELECT COUNT(*) FROM stuff')
        #}.to_not raise_error

        #expect {
        #  client.query('DELETE FROM stuff WHERE id = 99999')
        #}.to_not raise_error
      end

      it 'kills existing connections' do
        #client = create_client
        #client.query('SELECT 1')

        #QuotaEnforcer.enforce!

        #expect {
        #  client.query('SELECT 1')
        #}.to raise_error(Mysql2::Error, /server has gone away/)
      end

      it 'does not kill root connections' do
        #client = create_client
        #client.query('SELECT 1')

        #QuotaEnforcer.enforce!

        #expect {
        #  client.query('SELECT 1')
        #}.to_not raise_error
      end
    end

    context 'for a database that has already moved under its quota' do
      before do
        #client = create_client
        #overflow_database(client)
        #QuotaEnforcer.enforce!

        #client = create_client
        #prune_database(client)
        #QuotaEnforcer.enforce!
      end

      it 'does not kill existing connections' do
        #client = create_client
        #client.query('SELECT 1')

        #QuotaEnforcer.enforce!

        #expect {
        #  client.query('SELECT 1')
        #}.to_not raise_error
      end
    end

    def create_client
      #Mysql2::Client.new(
      #  :host     => binding.host,
      #  :port     => binding.port,
      #  :database => binding.database,
      #  :username => binding.username,
      #  :password => binding.password
      #)
     $stderr.write "LEONID quota_enforcer_spec.create_client binding=" + binding.to_s + "\n"
     connection = ServiceInstance.rdbi_connection(binding.username,binding.password)
     connection.execute("SET SCHEMA #{binding.database}").finish();
     connection
    end

    def create_root_client
      config = Rails.configuration.database_configuration[Rails.env]

      #Mysql2::Client.new(
      #  :host     => binding.host,
      #  :port     => binding.port,
      #  :database => binding.database,
      #  :username => config.fetch('username'),
      #  :password => config.fetch('password')
      #)
     $stderr.write "LEONID >> quota_enforcer_spec_spec.create_root_client config=" + config.to_s + "\n"
     #RDBI.connect :ODBC, :db => binding.dsn, :user => config.fetch('username'),:password => config.fetch('password')
     ServiceInstance.rdbi_system_connection()
    end

    def overflow_database(client)
      $stderr.write("LEONID quota_enforcer_spec.overflow_database\n")
      client.execute('CREATE COLUMN TABLE STUFF (ID INT PRIMARY KEY, DATA CLOB)').finish()
      id = 0
      max_storage_mb.times do |n|
        #client.execute("INSERT INTO stuff (id, data) VALUES (#{n}, '#{data}')").finish()
        data = id.to_s * (1024 * 1024)
        sql = "INSERT INTO stuff (id, data) VALUES (#{id.to_s}, '#{data}')"        
        client.execute(sql).finish()
        id = id + 1        
      end
      $stderr.write("LEONID << quota_enforcer_spec.overflow_database = " + ServiceInstance.rdbi_database_size(binding.database).to_s + "\n")
    end

    def prune_database(client)
      client.execute('DELETE FROM STUFF').finish()           
    end
  end
end
