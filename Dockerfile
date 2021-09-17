FROM php:7.3

RUN apt-get update && \
    apt-get install -qqy git unzip libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libaio1 wget \
        apt-utils libxml2-dev gnupg apt-transport-https && \
     apt-get clean autoclean && apt-get autoremove --yes &&  rm -rf /var/lib/{apt,dpkg,cache,log}/ 

RUN wget http://archive.ubuntu.com/ubuntu/pool/main/g/glibc/multiarch-support_2.27-3ubuntu1.4_amd64.deb && \
    apt-get install -y ./multiarch-support_2.27-3ubuntu1.4_amd64.deb && \
    rm ./multiarch-support_2.27-3ubuntu1.4_amd64.deb && \
    curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -     && \
    curl https://packages.microsoft.com/config/debian/9/prod.list > /etc/apt/sources.list.d/mssql-release.list     && \
    apt-get update     && \
    ACCEPT_EULA=Y apt-get -y --no-install-recommends install msodbcsql17 unixodbc-dev     && \
    pecl install sqlsrv     && pecl install pdo_sqlsrv     && echo "extension=pdo_sqlsrv.so" >> `php --ini | grep "Scan for additional .ini files" | sed -e "s|.*:\s*||"`/30-pdo_sqlsrv.ini     && echo "extension=sqlsrv.so" >> `php --ini | grep "Scan for additional .ini files" | sed -e "s|.*:\s*||"`/30-sqlsrv.ini

#composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# ORACLE oci 
RUN mkdir /opt/oracle \
    && cd /opt/oracle     
    
ADD files/instantclient-basic-linux.x64-12.1.0.2.0.zip /opt/oracle
ADD files/instantclient-sdk-linux.x64-12.1.0.2.0.zip /opt/oracle

# Install Oracle Instantclient
RUN  unzip /opt/oracle/instantclient-basic-linux.x64-12.1.0.2.0.zip -d /opt/oracle \
    && unzip /opt/oracle/instantclient-sdk-linux.x64-12.1.0.2.0.zip -d /opt/oracle \
    && ln -s /opt/oracle/instantclient_12_1/libclntsh.so.12.1 /opt/oracle/instantclient_12_1/libclntsh.so \
    && ln -s /opt/oracle/instantclient_12_1/libclntshcore.so.12.1 /opt/oracle/instantclient_12_1/libclntshcore.so \
    && ln -s /opt/oracle/instantclient_12_1/libocci.so.12.1 /opt/oracle/instantclient_12_1/libocci.so \
    && rm -rf /opt/oracle/*.zip
    
ENV LD_LIBRARY_PATH  /opt/oracle/instantclient_12_1:${LD_LIBRARY_PATH}
    
# Install Oracle extensions
RUN echo 'instantclient,/opt/oracle/instantclient_12_1/' | pecl install oci8-2.2.0 \ 
      && docker-php-ext-enable \
               oci8 \ 
       && docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,/opt/oracle/instantclient_12_1,12.1 \
       && docker-php-ext-install \
               pdo_oci intl mysqli pdo pdo_mysql soap
