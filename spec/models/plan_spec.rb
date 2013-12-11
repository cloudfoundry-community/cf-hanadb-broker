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

describe Plan do
  describe '.build' do
    it 'sets the attributes correctly' do
      plan = Plan.build(
        'id'          => 'plan_id',
        'name'        => 'plan_name',
        'description' => 'plan_description',
        'metadata'    => { 'meta_key' => 'meta_value' }
      )

      expect(plan.id).to eq('plan_id')
      expect(plan.name).to eq('plan_name')
      expect(plan.description).to eq('plan_description')
      expect(plan.metadata).to eq({ 'meta_key' => 'meta_value' })
    end

    context 'when the metadata key is missing' do
      let(:plan) do
        Plan.build(
          'id'          => 'plan_id',
          'name'        => 'plan_name',
          'description' => 'plan_description'
        )
      end

      it 'sets the field to nil' do
        expect(plan.metadata).to be_nil
      end
    end
  end

  describe '#to_hash' do
    it 'contains the correct values' do
      plan = Plan.new(
        'id'          => 'plan_id',
        'name'        => 'plan_name',
        'description' => 'plan_description',
        'metadata'    => { 'key1' => 'value1' }
      )

      expect(plan.to_hash.fetch('id')).to eq('plan_id')
      expect(plan.to_hash.fetch('name')).to eq('plan_name')
      expect(plan.to_hash.fetch('description')).to eq('plan_description')
      expect(plan.to_hash.fetch('metadata')).to eq({ 'key1' => 'value1' })
    end
  end
end