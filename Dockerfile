FROM npohosting/base:3.7

LABEL maintainer="NPO Hosting <hosting@npo.nl>"

# Installeren van de vereiste software
RUN echo "## Install Basic Tools" \
    && apk add --no-cache \
        mariadb-client \
        openssh \
        rsync \
        py2-pip \
        bash \
        curl \
    && pip install awscli

ADD root/ /
RUN chmod a+x /run.sh /report_result.sh

# /etc/passwd group writeable maken zodat arbitraire uids eventueel kunnen toegevoegd worden.
RUN chmod g=u /etc/passwd
USER 1001

CMD ["/run.sh"]
