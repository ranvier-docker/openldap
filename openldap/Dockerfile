FROM alpine:3

# Add Tini
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

# Install OpenLDAP and dependencies
RUN apk --update --no-cache add bash openldap openldap-clients openldap-back-mdb openssl ca-certificates

# Copy project files
COPY resources /app

# Change to /app/
WORKDIR /app/

# Run your program under Tini
CMD ["/app/entrypoint.sh"]
