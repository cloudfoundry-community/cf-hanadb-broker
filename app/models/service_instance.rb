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

class ServiceInstance
  attr_accessor :id
  def initialize id
    @id=id.fetch(:id).to_s
  end

  DATABASE_PREFIX = 'CFS_'.freeze

  def self.find_by_id(id)
    instance = new(id: id)
    count = rdbi_select_single_value("SELECT COUNT(*) FROM SYS.P_SCHEMAS_ WHERE NAME LIKE '#{instance.database}'")
    if( count == 0 )
      instance = nil
    end
    instance
  end

  def self.find(id)
    find_by_id(id) || raise("Couldn't find ServiceInstance with id=#{id}")
  end

  def self.exists?(id)
    find_by_id(id).present?
  end

  def self.get_number_of_existing_instances
    count = ServiceInstance.rdbi_select_single_value("SELECT COUNT(*) FROM SYS.P_SCHEMAS_ WHERE NAME LIKE '#{DATABASE_PREFIX}%'")
    count
  end

  def database
    @database ||= begin
      if id =~ /[^0-9,a-z,A-Z$-]+/
        raise 'Only ids matching [0-9,a-z,A-Z$-]+ are allowed'
      end
      @database = id.upcase.gsub('-', '_')
      "#{DATABASE_PREFIX}#{database}"
    end
  end

  def save
    ServiceInstance.rdbi_create_database(database);
  end

  def destroy
    ServiceInstance.rdbi_drop_database_if_exists(database);
  end

  def to_json(*)
    {
      'dashboard_url' => 'http://fake.dashboard.url'
    }.to_json
  end

  def self.connection_config
    Rails.configuration.database_configuration[Rails.env]
  end


  def self.rdbi_connection_ex(dsn, username, password)
    RDBI.connect :ODBC, :db => dsn, :user => username,:password => password    
  end
    
  def self.rdbi_connection(username, password)
    dsn = connection_config.fetch('dsn')
    ServiceInstance.rdbi_connection_ex( dsn, username, password )
  end
  def self.rdbi_system_connection()
    ServiceInstance.rdbi_connection( connection_config.fetch('username'), connection_config.fetch('password') )
  end
   
  def self.rdbi_create_database( database )
    ServiceInstance.rdbi_system_connection().execute("CREATE SCHEMA #{database}").finish();
  end

  def self.rdbi_drop_database( database )
    ServiceInstance.rdbi_system_connection().execute("DROP SCHEMA #{database} CASCADE").finish();
  end

  def self.rdbi_create_database_if_not_exists( database )
    begin
      ServiceInstance.rdbi_create_database(database);
    rescue Exception => e
      raise unless e.message =~ /cannot use duplicate schema name/
    end
  end

  def self.rdbi_drop_database_if_exists( database )
    begin
      ServiceInstance.rdbi_drop_database(database);
    rescue Exception => e
      raise unless e.message =~ /invalid schema name/
    end
  end

  def self.rdbi_create_user( username, password )
    ServiceInstance.rdbi_system_connection().execute("CREATE USER #{username} PASSWORD #{password}").finish()
    ServiceInstance.rdbi_connection(username, password).execute("GRANT ALTER, CREATE ANY, DEBUG, DELETE, DROP, EXECUTE, INDEX, INSERT, REFERENCES, SELECT, TRIGGER, UPDATE ON SCHEMA #{username} TO system").finish()
  end

  def self.rdbi_drop_user( username )
    begin
      c = ServiceInstance.rdbi_system_connection();
      c.execute("DROP USER #{username} CASCADE").finish()
    rescue Exception => e
      raise unless e.message =~ /invalid user name/
    end
  end

  def self.rdbi_grant_full_access_to_user( username, database )
    sql = "GRANT ALTER, CREATE ANY, DEBUG, DELETE, DROP, EXECUTE, INDEX, INSERT, REFERENCES, SELECT, TRIGGER, UPDATE ON SCHEMA #{database} TO #{username}"
    ServiceInstance.rdbi_system_connection().execute(sql).finish()
  end

  def self.rdbi_revoke_full_access_from_user( username, database )
    sql = "REVOKE ALTER, CREATE ANY, DEBUG, EXECUTE, INDEX, INSERT, REFERENCES, TRIGGER, UPDATE ON SCHEMA #{database} FROM #{username}"
    ServiceInstance.rdbi_system_connection().execute(sql).finish()
  end

  def self.rdbi_is_user_exists( username )
    ServiceInstance.rdbi_select_single_value("SELECT COUNT(*) FROM SYS.P_USERS_ WHERE NAME='#{username}'") > 0
  end  
  
  def self.rdbi_is_full_access_granted( username, database )
    ServiceInstance.rdbi_select_single_value("SELECT COUNT(*) FROM SYS.GRANTED_PRIVILEGES WHERE SCHEMA_NAME='#{database}' AND GRANTEE='#{username}' AND PRIVILEGE='INSERT'") > 0
  end

  def self.rdbi_select_single_value( sql )
    rs = ServiceInstance.rdbi_system_connection().execute(sql)
    val = rs.to_a.fetch(0).fetch(0)
    rs.finish
    val
  end

  def self.rdbi_is_database_exists( database )
    rdbi_select_single_value("SELECT DISTINCT COUNT(*) FROM SYS.P_SCHEMAS_ WHERE NAME = '#{database}'")
  end
  def self.rdbi_database_size( database )
    rdbi_select_single_value("
      SELECT SUM(SIZE) AS SIZE FROM (
        SELECT SCHEMA_NAME, SUM(MEMORY_SIZE_IN_TOTAL) AS SIZE FROM SYS.M_CS_TABLES GROUP BY SCHEMA_NAME
          UNION ALL
        SELECT SCHEMA_NAME, SUM(USED_FIXED_PART_SIZE) + SUM(USED_VARIABLE_PART_SIZE) AS SIZE  FROM SYS.M_RS_TABLES GROUP BY SCHEMA_NAME
      ) WHERE SCHEMA_NAME LIKE '#{database}' GROUP BY SCHEMA_NAME"
    )
  end 
end
