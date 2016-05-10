# encoding: utf-8
# author: Christoph Hartmann
# author: Dominik Richter
#
# prepare all operating systems with the required configuration


# basic tests
include_recipe('os_prepare::file')
include_recipe('os_prepare::mount') unless node['osprepare']['docker']
include_recipe('os_prepare::service')
include_recipe('os_prepare::package')
include_recipe('os_prepare::registry_key')
include_recipe('os_prepare::iptables') unless node['osprepare']['docker']

# configure repos, eg. nginx
include_recipe('os_prepare::apt')

# application configuration
if node['osprepare']['application']

  include_recipe('os_prepare::postgres')
  include_recipe('os_prepare::auditctl') unless node['osprepare']['docker']
  include_recipe('os_prepare::apache')

  # config file parsing
  include_recipe('os_prepare::json_yaml_csv_ini')
end
