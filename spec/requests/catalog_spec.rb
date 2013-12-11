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

describe 'GET /v2/catalog' do
  it 'returns the catalog of services' do
    get '/v2/catalog'

    expect(response.status).to eq(200)
    catalog = JSON.parse(response.body)

    services = catalog.fetch('services')
    expect(services).to have(1).service

    service = services.first
    expect(service.fetch('name')).to eq('p-hdb')
    expect(service.fetch('description')).to eq('HDB service for application development and testing')
    expect(service.fetch('bindable')).to be_true
    expect(service.fetch('metadata')).to eq(
      {
        'provider' => { 'name' => nil },
        'listing' => {
          'imageUrl' => nil,
          'blurb' => 'HDB service for application development and testing',
        }
      }
    )

    plans = service.fetch('plans')
    expect(plans).to have(1).plan

    plan = plans.first
    expect(plan.fetch('name')).to eq('512mb')
    expect(plan.fetch('description')).to eq('Shared HDB Server, 512mb persistent disk, 40 max concurrent connections')
    expect(plan.fetch('metadata')).to eq(
      {
        'cost' => 0.0,
        'bullets' => [
          { 'content' => 'Shared HDB server' },
          { 'content' => '512 MB storage' },
          { 'content' => '40 concurrent connections' },
        ]
      }
    )
  end
end
