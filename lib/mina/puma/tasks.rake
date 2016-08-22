require 'mina/bundler'
require 'mina/rails'
require 'mina/puma/utility'

namespace :puma do
  include Mina::Puma::Utility

  set :web_server, :puma

  set_default :puma_role,      -> { user }
  set_default :puma_env,       -> { fetch(:rails_env, 'production') }
  set_default :puma_config,    -> { "#{deploy_to}/#{shared_path}/config/puma.rb" }
  set_default :puma_socket,    -> { "#{deploy_to}/#{shared_path}/tmp/sockets/puma.sock" }
  set_default :puma_state,     -> { "#{deploy_to}/#{shared_path}/tmp/sockets/puma.state" }
  set_default :puma_pid,       -> { "#{deploy_to}/#{shared_path}/tmp/pids/puma.pid" }
  set_default :puma_cmd,       -> { "#{bundle_prefix} puma" }
  set_default :pumactl_cmd,    -> { "#{bundle_prefix} pumactl" }
  set_default :pumactl_socket, -> { "#{deploy_to}/#{shared_path}/tmp/sockets/pumactl.sock" }

  desc "Start Puma master process"
  task start: :environment do
    queue! start_puma
  end

  desc "Stop Puma"
  task stop: :environment do
    queue! kill_puma('QUIT')
  end

  desc "Immediately shutdown Puma"
  task shutdown: :environment do
    queue! kill_puma('TERM')
  end

  desc "Restart puma service"
  task restart: :environment do
    queue! restart_puma
  end

  desc "Restart puma service (hard restart)"
  task hard_restart: :environment do
    queue! kill_puma('QUIT')
    queue! start_puma
  end
end
