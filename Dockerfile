FROM alpine:latest
MAINTAINER Justin.h <jex.h@gmail.com>

ENV REDMINE_VERSION=3.3.0 \
    REDMINE_USER="redmine" \
    REDMINE_HOME="/home/redmine" \
    REDMINE_LOG_DIR="/var/log/redmine" \
    REDMINE_CACHE_DIR="/etc/docker-redmine" \
    RAILS_ENV=production

ENV REDMINE_INSTALL_DIR="${REDMINE_HOME}/redmine" \
    REDMINE_DATA_DIR="${REDMINE_HOME}/data" \
    REDMINE_BUILD_DIR="${REDMINE_CACHE_DIR}/build" \
    REDMINE_RUNTIME_DIR="${REDMINE_CACHE_DIR}/runtime"

WORKDIR ${REDMINE_INSTALL_DIR}

ENV BRANCH_NAME=master \
         RAILS_ENV=production

RUN addgroup -S redmine \
    && adduser -S -G redmine redmine \
	&& apk --no-cache add --virtual .run-deps \
            mariadb-client-libs \
	    	sqlite-libs \
            imagemagick \
            tzdata \
            ruby \
		    ruby-bigdecimal \
	    	ruby-bundler \
            tini \
            su-exec \
            bash \
    && apk --no-cache add --virtual .build-deps \
                build-base \
                ruby-dev \
                libxslt-dev \
                imagemagick-dev \
                mariadb-dev \
                sqlite-dev \
                linux-headers \
                patch \
                coreutils \
                curl \
                git \
    && echo 'gem: --no-document' > /etc/gemrc \
    && gem update --system \
	&& git clone -b ${BRANCH_NAME} https://github.com/redmine/redmine.git . \
    && rm -rf files/delete.me log/delete.me .git test\
    && mkdir -p tmp/pdf public/plugin_assets \
    && chown -R redmine:redmine ./\
	&& for adapter in mysql2 sqlite3; do \
		echo "$RAILS_ENV:" > ./config/database.yml; \
		echo "  adapter: $adapter" >> ./config/database.yml; \
		bundle install --without development test; \
	done \
	&& rm ./config/database.yml \
	&& rm -rf /root/* `gem env gemdir`/cache \
    && apk --purge del .build-deps


COPY assets/build/ ${REDMINE_BUILD_DIR}/
RUN bash ${REDMINE_BUILD_DIR}/install.sh

COPY assets/runtime/ ${REDMINE_RUNTIME_DIR}/
COPY assets/tools/ /usr/bin/
COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

EXPOSE 80/tcp 443/tcp

VOLUME ["${REDMINE_DATA_DIR}", "${REDMINE_LOG_DIR}"]

ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["app:start"]
