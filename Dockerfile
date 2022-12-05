FROM php:7.4-apache
RUN apt-get update && apt-get install -y jq
COPY src/ /var/www/html
COPY createApps.sh /usr/local/bin/createApps.sh
EXPOSE 80