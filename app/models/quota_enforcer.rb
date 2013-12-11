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

require 'rdbi-driver-odbc'

module QuotaEnforcer
  class << self
    QUOTA_IN_MB = Settings.services[0].plans[0].max_storage_mb.to_i rescue nil
    def enforce!
      raise 'You must specify a service and a plan' if QUOTA_IN_MB == nil
      revoke_privileges_from_violators
      grant_privileges_to_reformed
    end

    private

    def connection
      @connection ||= ServiceInstance.rdbi_system_connection()
    end

    def revoke_privileges_from_violators
      
      sql = "SELECT DISTINCT GRANTEE AS USERNAME, SCHEMA_NAME AS DATABASE FROM SYS.GRANTED_PRIVILEGES WHERE SCHEMA_NAME IN (
              	SELECT SCHEMA_NAME FROM (
                  	SELECT SCHEMA_NAME, SUM(SIZE) AS SIZE FROM (
                      	SELECT SCHEMA_NAME, SUM(MEMORY_SIZE_IN_TOTAL) AS SIZE FROM SYS.M_CS_TABLES GROUP BY SCHEMA_NAME
              	          UNION ALL
                  	    SELECT SCHEMA_NAME, SUM(USED_FIXED_PART_SIZE) + SUM(USED_VARIABLE_PART_SIZE) AS SIZE  FROM SYS.M_RS_TABLES GROUP BY SCHEMA_NAME
                    	) WHERE SCHEMA_NAME LIKE '#{ServiceInstance::DATABASE_PREFIX}%'
                  	GROUP BY SCHEMA_NAME
              	    HAVING ROUND(SUM(SIZE) / 1024 / 1024, 1) >= #{QUOTA_IN_MB}
                  )
              	ORDER BY SCHEMA_NAME
              )"
      rs = connection.execute(sql);
      violators = rs.fetch(:all, :Struct)
      puts violators.to_s
      rs.finish
      violators.each{ |v| ServiceInstance.rdbi_revoke_full_access_from_user(v[:USERNAME], v[:DATABASE]) }
    end

    def grant_privileges_to_reformed
      sql = "SELECT DISTINCT GRANTEE AS USERNAME, SCHEMA_NAME AS DATABASE FROM SYS.GRANTED_PRIVILEGES WHERE SCHEMA_NAME IN (
                SELECT SCHEMA_NAME FROM (
                    SELECT SCHEMA_NAME, SUM(SIZE) AS SIZE FROM (
                        SELECT SCHEMA_NAME, SUM(MEMORY_SIZE_IN_TOTAL) AS SIZE FROM SYS.M_CS_TABLES GROUP BY SCHEMA_NAME
                          UNION ALL
                        SELECT SCHEMA_NAME, SUM(USED_FIXED_PART_SIZE) + SUM(USED_VARIABLE_PART_SIZE) AS SIZE  FROM SYS.M_RS_TABLES GROUP BY SCHEMA_NAME
                      ) WHERE SCHEMA_NAME LIKE '#{ServiceInstance::DATABASE_PREFIX}%'
                    GROUP BY SCHEMA_NAME
                    HAVING ROUND(SUM(SIZE) / 1024 / 1024, 1) < #{QUOTA_IN_MB}
                  )
                ORDER BY SCHEMA_NAME
              )"
      rs = connection.execute(sql);      
      reformed = rs.fetch(:all, :Struct)
      puts reformed.to_s
      rs.finish
      reformed.each{ |v| ServiceInstance.rdbi_grant_full_access_to_user(v[:USERNAME], v[:DATABASE]) }
    end

    #
    # In order to change privileges immediately, we must do two things:
    # 1) Flush the privileges
    # 2) Kill any and all active connections
    #
    #    def reset_active_privileges(database)
    #      connection.execute('FLUSH PRIVILEGES')

    #      processes = connection.select('SHOW PROCESSLIST')
    #      processes.each do |process|
    #        id, db, user = process.values_at('Id', 'db', 'User')

    #        if db == database && user != 'root'
    #          connection.execute("KILL CONNECTION #{id}")
    #        end
    #      end
    #    end

    def reset_active_privileges(schema)
      $stderr.write "QuotaEnforcer::reset_active_privileges for \n" + schema + " NOT IMPLEMENTED YET\n";
    end
  end
end
