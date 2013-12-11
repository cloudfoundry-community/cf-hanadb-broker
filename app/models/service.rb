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

class Service
  attr_reader :id, :name, :description, :tags, :metadata, :plans

  def self.build(attrs)
    plan_attrs = attrs['plans'] || []
    plans      = plan_attrs.map { |attr| Plan.build(attr) }
    new(attrs.merge('plans' => plans))
  end

  def initialize(attrs)
    @id          = attrs.fetch('id')
    @name        = attrs.fetch('name')
    @description = attrs.fetch('description')
    @tags        = attrs.fetch('tags', [])
    @metadata    = attrs.fetch('metadata', nil)
    @plans       = attrs.fetch('plans', [])
  end

  def bindable?
    true
  end

  def to_hash
    {
      'id'          => self.id,
      'name'        => self.name,
      'description' => self.description,
      'tags'        => self.tags,
      'metadata'    => self.metadata,
      'plans'       => self.plans.map(&:to_hash),
      'bindable'    => self.bindable?
    }
  end

end
