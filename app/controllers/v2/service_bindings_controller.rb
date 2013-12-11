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

class V2::ServiceBindingsController < V2::BaseController
  def update
    instance = ServiceInstance.find(params.fetch(:service_instance_id))
    binding = ServiceBinding.new(id: params.fetch(:id), service_instance: instance)
    binding.save

    render status: 201, json: binding
  end

  def destroy
    if binding = ServiceBinding.find_by_id(params.fetch(:id))
      binding.destroy
      status = 204
    else
      status = 410
    end
    render status: status, json: {}
  end
end
