FROM ${$BASE_IMAGE_REPO}/srikanth-redmine-ruby:3.1.3.v1
WORKDIR /app
#Essentials
RUN apt-get update \
    && apt-get install build-essential \
    && apt install -y nodejs awscli jq
RUN mkdir -p shared/pids public/system shared/sockets nginx/cache nginx/logs \
    && chmod -R nobody. nginx/
COPY . ./
RUN bundle install --path /app/vendor/cache --without development test
RUN gem install set -v "1.0.3" \
    && gem install aws-sdk-secretsmanager
CMD ["/app/ci-cd/startup.sh"]