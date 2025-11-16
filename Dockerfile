FROM ubuntu:22.04

# Install dependencies in one layer
RUN apt-get update && apt-get install -y \
    software-properties-common \
    wget curl git openssh-client \
    tmate python3 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app
RUN echo "Tmate Session Running - $(date)" > index.html

# Use Railway's dynamic port
ENV PORT=80

# Create a startup script for proper process management
RUN cat > /app/start.sh << 'EOF'
#!/bin/bash
set -e

# Start web server on Railway's assigned port
python3 -m http.server $PORT &

# Generate a unique session name and log it
SESSION_NAME="railway-$(hostname)"
echo "=== TMATE SESSION INFO ===" > /app/tmate.info
echo "Session: $SESSION_NAME" >> /app/tmate.info

# Start tmate with controlled access
tmate -F -n -v -L /tmp/tmate.sock new-session -d
tmate -L /tmp/tmate.sock wait tmate-ready

# Display connection info
tmate -L /tmp/tmate.sock display -p '#{tmate_ssh}' >> /app/tmate.info
tmate -L /tmp/tmate.sock display -p '#{tmate_web}' >> /app/tmate.info

echo "SSH/Web URLs saved to /app/tmate.info"
cat /app/tmate.info

# Keep session alive
tmate -L /tmp/tmate.sock attach -F
EOF

RUN chmod +x /app/start.sh

# Expose Railway's default port
EXPOSE $PORT

CMD ["/app/start.sh"]
