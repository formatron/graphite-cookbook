actions :create_if_missing
default_action :create_if_missing

attribute :path, name_attribute: true, kind_of: String, required: true
attribute :user, kind_of: String, required: true
attribute :firstname, kind_of: String, required: true
attribute :lastname, kind_of: String, required: true
attribute :email, kind_of: String, required: true
attribute :password, kind_of: String, required: true
