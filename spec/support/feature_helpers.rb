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

# Inspired by rspec-rails' request example group.
module FeatureHelpers
  extend ActiveSupport::Concern
  include RSpec::Rails::RailsExampleGroup
  include ActionDispatch::Integration::Runner
  include ActionDispatch::Assertions
  include RSpec::Rails::Matchers::RedirectTo
  include RSpec::Rails::Matchers::RenderTemplate
  include ActionController::TemplateAssertions

  included do
    metadata[:type] = :feature

    let(:default_env) do
      username = Settings.auth_username
      password = Settings.auth_password

      {
        'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(username, password)
      }
    end
    let(:env) { default_env }

    before do
      @routes = ::Rails.application.routes
    end
  end

  def app
    ::Rails.application
  end

  def get(*args)
    args[2] ||= env
    super(*args)
  end

  def post(*args)
    args[2] ||= env
    super(*args)
  end

  def put(*args)
    args[2] ||= env
    super(*args)
  end

  def delete(*args)
    args[2] ||= env
    super(*args)
  end
end

RSpec.configure do |config|
  config.include FeatureHelpers, :example_group => { :file_path => %r(spec/features) }
end
