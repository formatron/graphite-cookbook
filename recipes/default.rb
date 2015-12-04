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

include_recipe 'build-essential::default'
chef_gem 'pbkdf256' do
  compile_time false
end

formatron_graphite_initial_data initial_data do
  user root_user
  firstname root_firstname
  lastname root_lastname
  password root_password
  email root_email
end

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

formatron_postgresql_user database_user do
  connection postgresql_connection_info
  password database_password
  create_db true
end

formatron_postgresql_database database_name do
  connection postgresql_connection_info_graphite
  notifies :run, "bash[init_db]", :immediately
end

bash 'init_db' do
  code <<-EOH.gsub(/^ {4}/, '')
    graphite-manage syncdb --noinput
    graphite-manage loaddata #{initial_data}
  EOH
  action :nothing
end
