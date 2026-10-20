#!/bin/bash

set -xe

APP_TYPE=${APP_TYPE:-puma}
SECRET_ID=${SECRET_ID:-app-secrets}
AWS_REGION=${AWS_REGION:-aws-region}
# Fetch secrets from AWS Secrets Manager
SECRETS=$(aws secretsmanager get-secret-value --secret-id "$SECRET_ID" --query SecretString --output text --region "$AWS_REGION")
# Check if SECRETS is fetched correctly
if [[ -z "$SECRETS" ]]; then
  echo ":x: Error: No secrets fetched for SECRET_ID=$SECRET_ID. Check AWS Secrets Manager permissions."
  exit 1
fi
echo ":white_check_mark: Secrets fetched successfully."
# Parse the JSON object and export each key-value pair as an environment variable
echo ":arrows_counterclockwise: Exporting secrets as environment variables..."
for key in $(echo "$SECRETS" | jq -r 'keys[]'); do
  value=$(echo "$SECRETS" | jq -r --arg key "$key" '.[$key]')
  export "$key"="$value"
  # Persist to /etc/environment to ensure availability in new shells
  echo "$key=\"$value\"" >> /etc/environment
done
echo ":white_check_mark: Environment variables exported."
# Load variables into current session
source /etc/environment
# Debugging: Print exported environment variables if VERBOSE=true
if [[ "$VERBOSE" == "true" ]]; then
  echo ":scroll: Exported Environment Variables:"
  env
fi

# cron service
service cron start

# redmin office365 plugin
git submodule init
git submodule update

# For Rails Console
sed -i 's/\r$//' /app/bin/rails


# Resolve all bundle dependencies (quiet mode to reduce log noise)
echo ":wrench: Installing Ruby gems..."
bundle install --quiet
echo ":rocket: APP_TYPE => ${APP_TYPE}"

RUN_DB_MIGRATE=${RUN_DB_MIGRATE:-true}

if [ "${RUN_DB_MIGRATE}" = "true" ]; then
    echo "=====> Running db migrate"
    RAILS_ENV=$RAILS_ENV bundle exec rake db:migrate
    # RAILS_ENV=$RAILS_ENV bundle exec rake redmine:plugins:migrate NAME=redmine_mail_ticket_sync_pro
    RAILS_ENV=$RAILS_ENV bundle exec rake assets:precompile
    # RAILS_ENV=$RAILS_ENV bundle exec rake scheduler:update_schedule
fi

# Ensure Foreman loads environment variables
export $(grep -v '^#' /etc/environment | xargs)
# if [ "$APP_TYPE" == "delayed_job" ]; then
#     echo "Generating delayed job Procfile"
#     # echo "=====> Starting delayed job"
#     # exec foreman start -f ./ci-cd/Procfile_delayed_job -d ./
# else
#     echo "====> Starting puma using foreman"
#     APP_ENV=$RAILS_ENV
#     # sed -i "s%ROBOTS_URL%$robotsurl%g" /etc/nginx/nginx.conf
#     # sed -i "s/#APP_ENV/$APP_ENV/g" /app/ci-cd/unicorn.conf
#     exec foreman start -f ./ci-cd/Procfile -d ./
# fi
echo ":rocket: Starting Puma using Foreman..."
APP_ENV=$RAILS_ENV
exec foreman start -f ./ci-cd/Procfile -d ./