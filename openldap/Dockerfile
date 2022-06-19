FROM ubuntu:22.04

# Add Tini
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

# Install OpenLDAP
RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y slapd ldap-utils openssl ca-certificates

# Copy project files
COPY resources /app

# Change to /app/
WORKDIR /app/

# Run your program under Tini
CMD ["/app/entrypoint.sh"]
