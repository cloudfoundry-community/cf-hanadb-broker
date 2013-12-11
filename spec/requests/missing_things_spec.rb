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

# Behavior when calling endpoints associated with things that do not exist.

describe 'endpoints' do
  describe 'deleting an instance' do
    context 'when the service instance does not exist' do
      it 'returns 410' do
        delete '/v2/service_instances/DOESNOTEXIST'
        expect(response.status).to eq(410)
      end
    end
  end

  describe 'deleting a service binding' do
    context 'when the service binding does not exist' do
      it 'returns 410' do
        delete '/v2/service_instances/service_instance_id/service_bindings/DOESNOTEXIST'
        expect(response.status).to eq(410)
      end
    end
  end
end
