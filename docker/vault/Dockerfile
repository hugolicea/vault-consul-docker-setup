FROM hashicorp/vault:1.18.0

# Install jq and netcat
RUN apk add --no-cache jq netcat-openbsd dos2unix curl

# Copy the scripts
COPY init-unseal.sh /vault/init-unseal.sh
COPY entrypoint.sh /vault/entrypoint.sh
COPY simple_entrypoint.sh /vault/simple_entrypoint.sh

# Fix line endings and make scripts executable with verbose output
RUN echo "Converting line endings..." && \
    dos2unix /vault/init-unseal.sh /vault/entrypoint.sh /vault/simple_entrypoint.sh && \
    echo "Setting permissions..." && \
    chmod +x /vault/init-unseal.sh /vault/entrypoint.sh /vault/simple_entrypoint.sh && \
    echo "Listing files:" && \
    ls -la /vault/ && \
    echo "Testing entrypoint exists:" && \
    test -x /vault/entrypoint.sh && echo "entrypoint.sh is executable" || echo "entrypoint.sh is NOT executable"

# Use shell form to avoid permission issues
ENTRYPOINT ["/bin/sh", "/vault/entrypoint.sh"]