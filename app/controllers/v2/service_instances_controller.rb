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

class V2::ServiceInstancesController < V2::BaseController
  # This is actually the create
  def update
    quota = Settings['services'][0]['max_db_per_node']
    existing_instances = ServiceInstance.get_number_of_existing_instances
    if !quota or existing_instances < quota
       instance = ServiceInstance.new(id: params.fetch(:id))
       instance.save
      render status: 201, json: instance
    else
      render status: 409, json: {}
    end

  end

  def destroy
    if instance = ServiceInstance.find_by_id(params.fetch(:id))
      instance.destroy
      status = 204
    else
      status = 410
    end

    render status: status, json: {}
  end
end
