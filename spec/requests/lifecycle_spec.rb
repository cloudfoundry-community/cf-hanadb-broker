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

# Provisions, binds, unbinds, deprovisions a service

def cleanup_user(username)
  ServiceInstance.rdbi_drop_user(username);
rescue
end

def cleanup_database(database)
  ServiceInstance.rdbi_drop_database(database);
rescue
end

def create_client(username, password, database)
  connection = ServiceInstance.rdbi_connection(username,password)
  connection.execute("SET SCHEMA #{database}").finish()
  connection
end

describe 'the service lifecycle' do
  let(:instance_id) { 'instance-1' }
  let(:binding_id) { 'binding-1' }
    
  let(:instance) { ServiceInstance.new(id: instance_id) }
  let(:binding) { ServiceBinding.new(id: binding_id, service_instance: instance) }
        
#  let(:password) { 'LfPw1' }
#  let(:username) { ServiceBinding.new(id: binding_id).username }
#  let(:dsn) { ServiceBinding.new(id: binding_id).dsn }
  let(:database)  { instance.database }
  let(:dsn)       { binding.dsn }    
  let(:username)  { binding.username }    
  let(:password)  { binding.password }    

  before do
    cleanup_user(username)
    cleanup_database(database)
  end

  after do
    cleanup_user(username)
    cleanup_database(database)
  end

  it 'provisions, binds, unbinds, deprovisions' do
    ##
    ## Provision the instance
    ##
    put "/v2/service_instances/#{instance_id}", {service_plan_id: 'PLAN-1'}

    expect(response.status).to eq(201)
    instance = JSON.parse(response.body)

    expect(instance.fetch('dashboard_url')).to eq('http://fake.dashboard.url')

    ##
    ## Bind
    ##
    put "/v2/service_instances/#{instance_id}/service_bindings/#{binding_id}"

    expect(response.status).to eq(201)
    instance = JSON.parse(response.body)

    #expect(instance.fetch('credentials')).to eq({
    #  'hostname' => 'localhost',
    #  'port' => 30015,
    #  'name' => database,
    #  'username' => username,
    #  'password' => password,
    #  'uri' => "sap://#{username}:#{password}@localhost:30015/#{database}?reconnect=true",
    #  'jdbcUrl' => "jdbc:sap://#{username}:#{password}@localhost:30015/#{database}",
    #  'dsn' => dsn
    #})

    ##
    ## Test the binding
    ##
    credentials = instance.fetch('credentials');
    client = create_client(credentials.fetch('username'), credentials.fetch('password'), credentials.fetch('name'))
    client.execute("CREATE TABLE DATA_VALUES (ID VARCHAR(20), DATA_VALUE VARCHAR(20))").finish()
    client.execute("INSERT INTO DATA_VALUES VALUES('123', '456')").finish()
    rs = client.execute("SELECT ID, DATA_VALUE FROM data_values");
    found = rs.fetch(:all, :Struct)
    rs.finish()
    expect(found[0][:DATA_VALUE]).to eq('456')
 
    ##
    ## Unbind
    ##
    delete "/v2/service_instances/#{instance_id}/service_bindings/#{binding_id}"
    expect(response.status).to eq(204)

    ##
    ## Test that the binding no longer works
    ##
    expect {
      create_client(username, password, database)
    }.to raise_error

    ##
    ## Test that we have purged any data associated with the user
    ##
    found = ServiceInstance.rdbi_is_user_exists(username) 
    expect(found).to eq(false)

    ##
    ## Deprovision
    ##
    delete "/v2/service_instances/#{instance_id}"
    expect(response.status).to eq(204)

    ##
    ## Test that the database no longer exists
    ##
    found = ServiceInstance.rdbi_is_database_exists(database)
    expect(found).to eq(0)
  end
end
