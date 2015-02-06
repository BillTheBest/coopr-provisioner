#
# Cookbook Name:: coopr_firewall
# Recipe:: default
#
# Copyright © 2013-2014 Cask Data, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

if node.key?('coopr_firewall')
  if node['coopr_firewall'].key?('unmanaged') && node['coopr_firewall']['unmanaged'].to_s == 'true'
    Chef::Log.info("Not managing host firewall per node['coopr_firewall']['unmanaged'] attribute")
  else
    include_recipe 'coopr_firewall::iptables'
  end
else
  include_recipe 'coopr_firewall::disable'
end
