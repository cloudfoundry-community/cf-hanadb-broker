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

class ServiceBinding
  attr_accessor :id, :service_instance
  
  USERNAME_PREFIX = 'CFU_'.freeze
  
  def initialize id
    @id=id.fetch(:id).to_s
    if( true == id.has_key?(:service_instance) )
      @service_instance=id.fetch(:service_instance)
    end
  end

  # Returns a given binding, if the SAP HANA user exists.
  #
  # NOTE: This method cannot currently check for the true existence of
  # the binding. A binding is the association of a SAP HANA user with a
  # database. We use the binding id to identify a user and the instance
  # id to identify a database. As such, we really need both ids to be
  # sure the binding exists. This problem is resolvable by persisting
  # both ids and their relationship in a separate management database.
  
  def self.find_by_id(id)
    binding = new(id: id)
    begin
      count = ServiceInstance.rdbi_select_single_value("SELECT COUNT(*) FROM SYS.USERS WHERE USER_NAME='#{binding.username}'");
      if count > 0
        binding
      else
        binding = nil
      end
      binding             
    rescue Exception => e
      raise unless e.message =~ /no such grant/
    end
  end

  # Returns a given binding, if it exists.
  #
  # NOTE: This method is only necessary because of the current
  # shortcomings of +find_by_id+. And because it requires both
  # the binding id and the instance id, it cannot currently be
  # used by the binding controller.

  def self.find_by_id_and_service_instance_id(id, instance_id)
    instance = ServiceInstance.new(id: instance_id)
    binding = new(id: id, service_instance: instance)

    begin
      count = ServiceInstance.rdbi_select_single_value("SELECT COUNT(*) FROM SYS.GRANTED_PRIVILEGES WHERE SCHEMA_NAME='#{instance.database}' AND GRANTEE='#{binding.username}' AND PRIVILEGE='INSERT'")
      if count > 0
        binding
      else
        binding = nil
      end        
    rescue Exception => e
      raise unless e.message =~ /no such grant/
    end
  end

  # Checks to see if the given binding exists.
  #
  # NOTE: This method uses +find_by_id_and_service_instance_id+ to
  # verify true existence, and thus cannot currently be used by the
  # binding controller.

  def self.exists?(conditions)
    id = conditions.fetch(:id)
    instance_id = conditions.fetch(:service_instance_id)
    find_by_id_and_service_instance_id(id, instance_id).present?    
  end

  def dsn
    connection_config.fetch('dsn')
  end
 
  def host
    connection_config.fetch('host')
  end

  def port
    connection_config.fetch('port')
  end

  def database
    service_instance.database
  end

  def username
    @username ||= USERNAME_PREFIX + (Digest::MD5.base64digest(id).gsub(/[^a-zA-Z0-9]+/, '')[0...12]).to_s.upcase
    @username
  end

  def password
    @password ||= ( SecureRandom.base64(20).gsub(/[^a-zA-Z0-9]+/, '')[0...32] + SecureRandom.hex(20)[0...32] )  
    @password
  end

  def save
    ServiceInstance.rdbi_create_user(username, password);
    ServiceInstance.rdbi_grant_full_access_to_user(username, database);
  end

  def destroy
    ServiceInstance.rdbi_drop_user(username)
  end

  def to_json(*)
    {
      'credentials' => {
      'hostname' => host,
      'port' => port,
      'name' => database,
      'username' => username,
      'password' => password,
      'uri' => uri,
      'jdbcUrl' => jdbc_url,
      'dsn' => dsn
      }
    }.to_json
  end

  private

  def uri
    "sap://#{username}:#{password}@#{host}:#{port}/#{database}?currentschema=#{database}"
  end

  def jdbc_url
    "jdbc:sap://#{username}:#{password}@#{host}:#{port}/#{database}?currentschema=#{database}"
  end

  def connection_config
    ServiceInstance.connection_config()
  end  
end
