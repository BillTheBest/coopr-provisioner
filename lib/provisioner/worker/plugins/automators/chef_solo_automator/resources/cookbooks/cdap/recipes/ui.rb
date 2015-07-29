#
# Cookbook Name:: cdap
# Recipe:: ui
#
# Copyright © 2013-2015 Cask Data, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe 'nodejs::default'
link '/usr/bin/node' do
  to '/usr/local/bin/node'
  action :create
  not_if 'test -e /usr/bin/node'
end

include_recipe 'cdap::repo'

package 'cdap-ui' do
  action :install
  version node['cdap']['version']
end

if node['cdap'].key?('ui')
  my_vars = { :options => node['cdap']['ui'] }

  directory '/etc/default' do
    owner 'root'
    group 'root'
    mode '0755'
    action :create
  end

  template '/etc/default/cdap-ui' do
    source 'generic-env.sh.erb'
    mode '0755'
    owner 'root'
    group 'root'
    action :create
    variables my_vars
  end # End /etc/default/cdap-ui
end

template '/etc/init.d/cdap-ui' do
  source 'cdap-service.erb'
  mode 0755
  owner 'root'
  group 'root'
  action :create
  variables node['cdap']['ui']
end

service 'cdap-ui' do
  status_command 'service cdap-ui status'
  action node['cdap']['ui']['init_actions']
end
