# config/puma.rb

# Get the app environment from APP_ENV or default to development
rails_env = ENV.fetch('APP_ENV', 'development')
environment rails_env

# App directory
app_dir = '/app'
shared_dir = "#{app_dir}/shared"

# Set up socket location
bind "unix://#{shared_dir}/sockets/puma.sock"
bind 'tcp://0.0.0.0:3000' # Added TCP port binding

# Logging
stdout_redirect "#{app_dir}/log/puma.stdout.log", "#{app_dir}/log/puma.stderr.log", true

# PID and state files
pidfile "#{shared_dir}/pids/puma.pid"
state_path "#{shared_dir}/pids/puma.state"

# Number of Puma workers
workers 3

# Thread settings (min/max per worker)
threads_count = ENV.fetch('RAILS_MAX_THREADS', 5).to_i
threads threads_count, threads_count

# Preload the application
preload_app!

# Hook to disconnect DB connection before forking
before_fork do
  ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord::Base)
end

# Hook to re-establish DB connection & reset cache in worker
on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord::Base)
  begin
    Rails.cache.try(:reset)
  rescue StandardError
    nil
  end

  # Load the custom initializer and set secrets
  load File.expand_path("#{app_dir}/config/initializers/secret_manager.rb")
  set_aws_managed_secrets
end