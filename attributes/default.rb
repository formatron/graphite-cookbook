default['formatron_graphite']['hostname'] = node['fqdn']
default['formatron_graphite']['secret_key'] = 'changeme'
default['formatron_graphite']['timezone'] = 'Europe/Amsterdam'
default['formatron_graphite']['postgresql']['user'] = 'postgres'
default['formatron_graphite']['postgresql']['password'] = 'changeme'
default['formatron_graphite']['database']['host'] = 'localhost'
default['formatron_graphite']['database']['port'] = 5432
default['formatron_graphite']['database']['name'] = 'graphite'
default['formatron_graphite']['database']['user'] = 'graphite'
default['formatron_graphite']['database']['password'] = 'changeme'
default['formatron_graphite']['root_user'] = 'root'
default['formatron_graphite']['root_firstname'] = ''
default['formatron_graphite']['root_lastname'] = ''
default['formatron_graphite']['root_password'] = 'changeme'
default['formatron_graphite']['root_email'] = ''

# if ldap_server is nil then LDAP will not be used
default['formatron_graphite']['ldap_server'] = nil
default['formatron_graphite']['ldap_port'] = nil
default['formatron_graphite']['ldap_search_base'] = nil
default['formatron_graphite']['ldap_bind_dn'] = nil
default['formatron_graphite']['ldap_bind_password'] = nil
default['formatron_graphite']['ldap_uid'] = nil
