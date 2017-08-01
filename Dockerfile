## -*- docker-image-name: "scaleway/wordpress:xenial" -*-
FROM scaleway/ubuntu:amd64-xenial
# following 'FROM' lines are used dynamically thanks do the image-builder
# which dynamically update the Dockerfile if needed.
#FROM scaleway/ubuntu:armhf-xenial    # arch=armv7l
#FROM scaleway/ubuntu:arm64-xenial    # arch=arm64
#FROM scaleway/ubuntu:i386-xenial     # arch=i386
#FROM scaleway/ubuntu:mips-xenial     # arch=mips


MAINTAINER Scaleway <opensource@scaleway.com> (@scaleway)

# Prepare rootfs for image-builder
RUN /usr/local/sbin/builder-enter

# Pre-seeding for postfix
RUN sudo su root -c "debconf-set-selections <<< \"postfix postfix/main_mailer_type string 'Internet Site'\"" \
  && sudo su root -c "debconf-set-selections <<< \"postfix postfix/mailname string localhost\""

# Install packages
RUN apt-get -q update     \
 && apt-get -q -y upgrade \
 && apt-get install -y -q \
        mailutils         \
        mysql-server-5.7  \
        nginx             \
        php7.0            \
        php7.0-cli        \
        php7.0-curl       \
        php7.0-fpm        \
        php7.0-gd         \
        php7.0-json       \
        php7.0-mcrypt     \
        php7.0-mbstring   \
        php7.0-mysql      \
        php7.0-xml        \
        pwgen             \
 && apt-get clean

# Uninstall apache
RUN apt-get -yq remove apache2

ENV WORDPRESS_VERSION 4.8

# Patch rootfs
ADD ./patches/root/ /root/
ADD ./patches/etc/ /etc/
ADD ./patches/usr/local/ /usr/local/

# Install WordPress
RUN wget -qO wordpress.tar.gz https://wordpress.org/wordpress-$WORDPRESS_VERSION.tar.gz && \
    tar -xzf wordpress.tar.gz && \
    rm -rf /var/www && \
    mv wordpress /var/www && \
    rm -f /var/www/wp-config-sample.php && \
    /usr/local/bin/wp_config.sh && \
    rm -f /usr/local/bin/wp_config.sh && \
    rm -f wordpress.tar.gz

# Configure NginX
RUN ln -sf /etc/nginx/sites-available/000-default.conf /etc/nginx/sites-enabled/000-default.conf && \
    rm -f /etc/nginx/sites-enabled/default

# Enable the init service. systemctl enable cannot be used as init is not running.
RUN ln -s /etc/systemd/system/init-wordpress.service /etc/systemd/system/multi-user.target.wants && \
    ln -s /etc/systemd/system/init-mysql.service /etc/systemd/system/multi-user.target.wants

# Clean rootfs from image-builder
RUN /usr/local/sbin/builder-leave
