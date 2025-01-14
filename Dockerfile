FROM debian:jessie
MAINTAINER Odoo S.A. <info@odoo.com>

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN set -x; \
        apt-get update \
        && apt-get install -y --no-install-recommends \
            ca-certificates \
            curl \
            node-less \
            python-gevent \
            python-pip \
            python-renderpm \
            python-support \
            python-watchdog \
            gcc g++ python-dev cmake\
        && curl -o wkhtmltox.deb -SL http://nightly.odoo.com/extra/wkhtmltox-0.12.1.2_linux-jessie-amd64.deb \
        && curl -o a.deb -SL http://ftp.br.debian.org/debian/pool/main/o/openbabel/openbabel_2.3.2+dfsg-2_amd64.deb \
        && curl -o b.deb -SL http://ftp.br.debian.org/debian/pool/main/o/openbabel/libopenbabel4_2.3.2+dfsg-2_amd64.deb \
        && curl -o c.deb -SL http://ftp.br.debian.org/debian/pool/main/g/gcc-4.9/libgomp1_4.9.2-10+deb8u1_amd64.deb \
        && echo '40e8b906de658a2221b15e4e8cd82565a47d7ee8 wkhtmltox.deb' | sha1sum -c - \
        && dpkg --force-depends -i wkhtmltox.deb \
        && dpkg --force-depends -i a.deb b.deb c.deb \
        && apt-get -y install -f --no-install-recommends \
        && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false npm \
        && rm -rf /var/lib/apt/lists/* wkhtmltox.deb \
        && pip install psycogreen==1.0 

# Install Odoo
ENV ODOO_VERSION 10.0
ENV ODOO_RELEASE 20180710
RUN set -x; \
        curl -o odoo.deb -SL http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/odoo_${ODOO_VERSION}.${ODOO_RELEASE}_all.deb \
        && echo '5aa056fa00a2f405652ba1386807c59ae563af29 odoo.deb' | sha1sum -c - \
        && dpkg --force-depends -i odoo.deb \
        && apt-get update \
        && apt-get -y install -f --no-install-recommends \
        && rm -rf /var/lib/apt/lists/* odoo.deb \ 
        && pip install pycrypto

# Copy entrypoint script and Odoo configuration file
COPY ./entrypoint.sh /
COPY ./odoo.conf /etc/odoo/
RUN chmod +x /entrypoint.sh
RUN chown odoo /etc/odoo/odoo.conf

# Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
RUN mkdir -p /mnt/extra-addons \
        && chown -R odoo /mnt/extra-addons
VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

# Expose Odoo services
EXPOSE 8069 8071

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

# Set default user when running the container
USER root

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
