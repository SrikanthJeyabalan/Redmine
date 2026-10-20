# generate_secrets.rb

require 'aws-sdk-secretsmanager'
require 'erb'

def fetch_secrets
  # secret names created in aws secrets manger
  db_secret_name = "#{ENV['APP_NAME']}/#{ENV['RAILS_ENV']}/mysql/connection_string"
  settings_secrets = "#{ENV['APP_NAME']}/#{ENV['RAILS_ENV']}/settings/secrets"

  region = "#{ENV['AWS_REGION']}"
  client = Aws::SecretsManager::Client.new(region: region)

  begin
    # fetch postgreSQL connection string
    db_secret_value_respone = client.get_secret_value(secret_id: db_secret_name)

    # fetch app setting secrets
    settings_secrets_value_response = client.get_secret_value(secret_id: settings_secrets)
  rescue Aws::SecretsManager::Errors::DecryptionFailure, Aws::SecretsManager::Errors::InternalServiceError,
         Aws::SecretsManager::Errors::InvalidNextTokenException, Aws::SecretsManager::Errors::InvalidRequestException,
         Aws::SecretsManager::Errors::ResourceNotFoundException => e
    raise
  else
    if db_secret_value_respone.secret_string
      db_secret_hash = JSON.parse(db_secret_value_respone.secret_string)
      settings_secrets_hash = JSON.parse(settings_secrets_value_response.secret_string)

      # set postgreSQL environment variable
      ENV['DATABASE_NAME'] = db_secret_hash['dbname']
      ENV['DATABASE_HOST'] = db_secret_hash['dbhost']
      ENV['DATABASE_USERNAME'] = db_secret_hash['dbusername']
      ENV['DATABASE_PASSWORD'] = db_secret_hash['dbpassword']

      # app setting environment variables
      # Rails Configuration
      ENV['SECRET_KEY_BASE']                    = settings_secrets_hash['secret_key_base']
      ENV['RAILS_MASTER_KEY']                   = settings_secrets_hash['rails_master_key']
      ENV['PRIMARY_KEY']                        = settings_secrets_hash['primary_key']
      ENV['SECONDARY_KEY']                      = settings_secrets_hash['secondary_key']
      ENV['KEY_DERIVATION_SALT']                = settings_secrets_hash['key_derivation_salt']
      ENV['REDMINE_SMTP_USERNAME']              = settings_secrets_hash['redmmine_smtp_username']
      ENV['REDMINE_SMTP_PASSWORD']              = settings_secrets_hash['redmine_smtp_password']
      ENV['AWS_ACCESS_KEY']                     = settings_secrets_hash['aws_access_key']
      ENV['AWS_SECRET_KEY']                     = settings_secrets_hash['aws_secret_key']
      ENV['REDMINE_FILE_ATTACHEMENT_S3_BUCKET'] = settings_secrets_hash['redmine_files_attachment_s3_bucket']
      ENV['REDMINE_PREFIX_PATH']                = settings_secrets_hash['redmine_prefix_path']
      ENV['AWS_REGION']                         = settings_secrets_hash['aws_region']

      # Populate the values in the ERB template for database.yml
      database_template = File.read('config/database.yml.erb')
      erb_database_template = ERB.new(database_template)
      database_result = erb_database_template.result(binding)

      # Write the generated content to database.yml
      File.write('config/database.yml', database_result)

      # Populate the values in the ERB template for settings.yml
      settings_template = File.read('config/settings.yml.erb')
      erb_settings_template = ERB.new(settings_template)
      settings_result = erb_settings_template.result(binding)

      # Write the generated content to settings.yml
      File.write('config/settings.yml', settings_result)
    end
  end
end

# Execute the fetch_secrets method
fetch_secrets