# frozen_string_literal: true
# server-based syntax
# ======================
# Defines a single server with a list of roles and multiple properties.
# You can define all roles on a single server, or split them:

# server 'example.com', user: 'deploy', roles: %w{app db web}, my_property: :my_value
# server 'example.com', user: 'deploy', roles: %w{app web}, other_property: :other_value
# server 'db.example.com', user: 'deploy', roles: %w{db}
# If you're provisioning half of Figgy at a time, you can do `ROLES=group_a cap production deploy`
# and it will deploy the same group_a as is defined in Ansible.
server "figgy-web-prod1.princeton.edu", user: "deploy", roles: %w[app db production_db web group_a]
server "figgy-web-prod2.princeton.edu", user: "deploy", roles: %w[app web group_a]
server "figgy-web-prod3.princeton.edu", user: "deploy", roles: %w[app web group_b]
server "figgy-web-prod4.princeton.edu", user: "deploy", roles: %w[app web group_b]
server "figgy-worker-prod1.princeton.edu", user: "deploy", roles: %w[worker web group_a worker_db]
server "figgy-worker-prod2.princeton.edu", user: "deploy", roles: %w[worker web group_a]
server "figgy-worker-prod3.princeton.edu", user: "deploy", roles: %w[worker web group_a]
server "figgy-worker-prod4.princeton.edu", user: "deploy", roles: %w[worker web group_b]
server "figgy-worker-prod5.princeton.edu", user: "deploy", roles: %w[worker web group_b]
server "figgy-worker-prod6.princeton.edu", user: "deploy", roles: %w[worker web group_b]

set :google_fixity_request_topic, "figgy-production-fixity-request"
set :google_service_account, "figgy-preservation-production@pulibrary-figgy-storage-1.iam.gserviceaccount.com"
set :google_fixity_bucket, "figgy-preservation"
set :google_fixity_status_topic, "figgy-production-fixity-status"

# role-based syntax
# ==================

# Defines a role with one or multiple servers. The primary server in each
# group is considered to be the first unless any  hosts have the primary
# property set. Specify the username and a domain or IP for the server.
# Don't use `:all`, it's a meta role.

# role :app, %w{deploy@example.com}, my_property: :my_value
# role :web, %w{user1@primary.com user2@additional.com}, other_property: :other_value
# role :db,  %w{deploy@example.com}

# Configuration
# =============
# You can set any configuration variable like in config/deploy.rb
# These variables are then only loaded and set in this stage.
# For available Capistrano configuration variables see the documentation page.
# http://capistranorb.com/documentation/getting-started/configuration/
# Feel free to add new variables to customise your setup.

# Custom SSH Options
# ==================
# You may pass any option but keep in mind that net/ssh understands a
# limited set of options, consult the Net::SSH documentation.
# http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start
#
# Global options
# --------------
#  set :ssh_options, {
#    keys: %w(/home/rlisowski/.ssh/id_rsa),
#    forward_agent: false,
#    auth_methods: %w(password)
#  }
#
# The server-based syntax can be used to override options:
# ------------------------------------
# server 'example.com',
#   user: 'user_name',
#   roles: %w{web app},
#   ssh_options: {
#     user: 'user_name', # overrides user setting above
#     keys: %w(/home/user_name/.ssh/id_rsa),
#     forward_agent: false,
#     auth_methods: %w(publickey password)
#     # password: 'please use keys'
#   }
