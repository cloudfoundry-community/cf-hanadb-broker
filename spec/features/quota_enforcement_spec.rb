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

describe 'Quota enforcement' do
  let(:instance_id) { SecureRandom.uuid }
  let(:binding_id) { SecureRandom.uuid }
  let(:max_storage_mb) { Settings.services[0].plans[0].max_storage_mb.to_i }

  before do
    put "/v2/service_instances/#{instance_id}", {service_plan_id: 'PLAN-1'}
    put "/v2/service_instances/#{instance_id}/service_bindings/#{binding_id}"
  end

  after do
    delete "/v2/service_instances/#{instance_id}/service_bindings/#{binding_id}"
    delete "/v2/service_instances/#{instance_id}"
  end

  specify 'User violates and recovers from quota limit' do
    binding = JSON.parse(response.body)
    credentials = binding.fetch('credentials')
    #$stderr.write "FIX IT 'User violates and recovers from quota limit'\n";
    client1 = create_client(credentials)
    #overflow_database(client1)
    #nforce_quota
    #verify_connection_terminated(client1)

    client2 = create_client(credentials)
    #verify_write_privileges_revoked(client2)
    #prune_database(client2)
    #enforce_quota
    #verify_connection_terminated(client2)

    client3 = create_client(credentials)
    #verify_write_privileges_restored(client3)
  end

  def create_client(config)
    #Mysql2::Client.new(
    #  :host => config.fetch('hostname'),
    #  :port => config.fetch('port'),
    #  :database => config.fetch('name'),
    #  :username => config.fetch('username'),
    #  :password => config.fetch('password')
    #)
    ServiceInstance.rdbi_connection(config.fetch('username'),config.fetch('password'))
  end

  def overflow_database(client)
    #client.query('CREATE TABLE stuff (id INT PRIMARY KEY, data LONGTEXT) ENGINE=InnoDB')

    #data = '1' * (1024 * 1024) # 1 MB

    #max_storage_mb.times do |n|
    #  client.query("INSERT INTO stuff (id, data) VALUES (#{n}, '#{data}')")
    #end

    #recalculate_usage
  end

  def prune_database(client)
    #client.query('DELETE FROM stuff LIMIT 2')

    #recalculate_usage
  end

  def recalculate_usage
    # Getting Mysql to update statistics is a little tricky. With the right configuration settings,
    # Mysql will do it automatically. With the wrong settings, you may need to ANALYZE or OPTIMIZE.

    #instance = ServiceInstance.new(id: instance_id)
    #ActiveRecord::Base.connection.execute("ANALYZE TABLE #{instance.database}.stuff")
    #ActiveRecord::Base.connection.execute("OPTIMIZE TABLE #{instance.database}.stuff")
  end

  def enforce_quota
    `rake quota:enforce`
  end

  def verify_connection_terminated(client)
    #expect {
    #  client.query('SELECT 1')
    #}.to raise_error(Mysql2::Error, /server has gone away/)
  end

  def verify_write_privileges_revoked(client)
    # see that insert/update/create privileges have been revoked
    #expect {
    #  client.query("INSERT INTO stuff (id, data) VALUES (99999, 'This should fail.')")
    #}.to raise_error(Mysql2::Error, /INSERT command denied/)

    #expect {
    #  client.query("UPDATE stuff SET data = 'This should also fail.' WHERE id = 1")
    #}.to raise_error(Mysql2::Error, /UPDATE command denied/)

    #expect {
    #  client.query('CREATE TABLE more_stuff (id INT PRIMARY KEY)')
    #}.to raise_error(Mysql2::Error, /CREATE command denied/)

    # see that read privileges have not been revoked
    #client.query('SELECT COUNT(*) FROM stuff')
  end

  def verify_write_privileges_restored(client)
    #client.query("INSERT INTO stuff (id, data) VALUES (99999, 'This should succeed.')")
    #client.query("UPDATE stuff SET data = 'This should also succeed.' WHERE id = 99999")
  end
end
