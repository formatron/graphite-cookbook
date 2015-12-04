require 'time'

def whyrun_supported?
  true
end

use_inline_resources

action :create_if_missing do
  # late require to allow the gem to be installed first
  require 'pbkdf256'
  path = new_resource.path
  user = new_resource.user
  firstname = new_resource.firstname
  lastname = new_resource.lastname
  email = new_resource.email
  password = new_resource.password
  created_time = Time.now.utc.xmlschema(3).chomp('Z')
  password_hash_iterations = 12000
  password_salt = SecureRandom.random_number(36**12).to_s 36
  password_hash = Base64.encode64 PBKDF256.dk(
    password,
    password_salt,
    password_hash_iterations,
    32
  )
  password_field = "pbkdf2_sha256$#{password_hash_iterations}" \
                   "$#{password_salt}$#{password_hash}".chomp
  template path do
    cookbook 'formatron_graphite'
    source 'initial_data.json.erb'
    variables(  
      user: user,
      firstname: firstname,
      lastname: lastname,
      last_login: created_time,
      password_field: password_field,
      email: email,
      date_joined: created_time
    )
    action :create_if_missing
  end
end
