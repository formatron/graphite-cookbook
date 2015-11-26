node.override['build-essential']['compile_time'] = true
include_recipe 'build-essential::default'
chef_gem 'pbkdf256' do
  compile_time true
end

require 'time'
require 'pbkdf256'

hostname = node['formatron_graphite']['hostname']
secret_key = node['formatron_graphite']['secret_key']
timezone = node['formatron_graphite']['timezone']
postgres_user = node['formatron_graphite']['postgresql']['user']
postgres_password = node['formatron_graphite']['postgresql']['password']
database_host = node['formatron_graphite']['database']['host']
database_port = node['formatron_graphite']['database']['port']
database_name = node['formatron_graphite']['database']['name']
database_user = node['formatron_graphite']['database']['user']
database_password = node['formatron_graphite']['database']['password']
root_user = node['formatron_graphite']['root_user']
root_firstname = node['formatron_graphite']['root_firstname']
root_lastname = node['formatron_graphite']['root_lastname']
root_password = node['formatron_graphite']['root_password']
root_email = node['formatron_graphite']['root_email']
ldap_server = node['formatron_graphite']['ldap_server']
ldap_port = node['formatron_graphite']['ldap_port']
ldap_search_base = node['formatron_graphite']['ldap_search_base']
ldap_bind_dn = node['formatron_graphite']['ldap_bind_dn']
ldap_bind_password = node['formatron_graphite']['ldap_bind_password']
ldap_uid = node['formatron_graphite']['ldap_uid']

package 'graphite-carbon'
package 'graphite-web'
package 'libpq-dev'
package 'python-psycopg2'
package 'python-ldap'

file '/etc/default/graphite-carbon' do
  content 'CARBON_CACHE_ENABLED=true'
end

cookbook_file '/etc/carbon/carbon.conf'
cookbook_file '/etc/carbon/storage-aggregation.conf'

service 'carbon-cache' do
  supports status: true, restart: true, reload: false
  action [ :enable, :start ]
end

template '/etc/apache2/sites-available/graphite.conf' do
  variables(
    hostname: hostname
  )
end

graphite_dir = '/etc/graphite'
settings = File.join graphite_dir, 'local_settings.py'
initial_data = File.join graphite_dir, 'initial_data.json'

template settings do
  variables(
    ldap_server: ldap_server,
    ldap_port: ldap_port,
    ldap_search_base: ldap_search_base,
    ldap_bind_dn: ldap_bind_dn,
    ldap_bind_password: ldap_bind_password,
    ldap_uid: ldap_uid,
    secret_key: secret_key,
    timezone: timezone,
    name: database_name,
    user: database_user,
    password: database_password,
    host: database_host,
    port: database_port
  )
end

root_created_time =
  node['formatron_graphite']['root_created_time'] ||
  node.set['formatron_graphite']['root_created_time'] =
    Time.now.utc.xmlschema(3).chomp('Z')
root_password_hash_iterations = 12000
root_password_salt = SecureRandom.random_number(36**12).to_s 36
root_password_hash = Base64.encode64 PBKDF256.dk(
  root_password,
  root_password_salt,
  root_password_hash_iterations,
  32
)
root_password_field =
  node['formatron_graphite']['root_password_field'] ||
  node.set['formatron_graphite']['root_password_field'] =
    "pbkdf2_sha256$#{root_password_hash_iterations}$#{root_password_salt}$#{root_password_hash}".chomp
template initial_data do
  variables(  
    root_user: root_user,
    root_firstname: root_firstname,
    root_lastname: root_lastname,
    last_login: root_created_time,
    root_password_field: root_password_field,
    root_email: root_email,
    date_joined: root_created_time
  )
end

include_recipe 'database::postgresql'

postgresql_connection_info = {
  host: database_host,
  port: database_port,
  username: postgres_user,
  password: postgres_password
}

postgresql_connection_info_graphite = {
  host: database_host,
  port: database_port,
  username: database_user,
  password: database_password
}

postgresql_database_user database_user do
  connection postgresql_connection_info
  password database_password
  createdb true
  action :create
end

postgresql_database database_name do
  connection postgresql_connection_info_graphite
  action :create
  notifies :run, "bash[init_db]", :immediately
end

bash 'init_db' do
  code <<-EOH.gsub(/^ {4}/, '')
    graphite-manage syncdb --noinput
    graphite-manage loaddata #{initial_data}
  EOH
  action :nothing
end
