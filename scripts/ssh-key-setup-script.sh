#!/bin/bash
# Explained line-by-line: https://bashsnippets.xyz/snippets/ssh-key-setup-script

CHECK="✓"
CROSS="✗"

# --- Configuration ---
KEY_TYPE="ed25519"               # Recommended: ed25519 (modern) or rsa (legacy)
KEY_BITS="4096"                  # Only used for RSA keys
KEY_COMMENT="$(whoami)@$(hostname)-$(date '+%Y%m%d')"
KEY_FILE="$HOME/.ssh/id_${KEY_TYPE}"
REMOTE_USER=""                   # Set to: user@server-ip to auto-copy key
                                 # Leave empty to skip remote copy

echo "SSH Key Setup Script"
echo "===================="

# --- Create .ssh directory with correct permissions ---
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
echo "$CHECK .ssh directory ready (chmod 700)"

# --- Check if key already exists ---
if [ -f "$KEY_FILE" ]; then
  echo "$CROSS Key already exists at $KEY_FILE"
  echo "  Delete it first if you want a new key: rm $KEY_FILE ${KEY_FILE}.pub"
  exit 0
fi

# --- Generate the key ---
echo "Generating ${KEY_TYPE} key..."
if ssh-keygen -t "$KEY_TYPE" -C "$KEY_COMMENT" -f "$KEY_FILE" -N ""; then
  echo "$CHECK Key generated: $KEY_FILE"
  chmod 600 "$KEY_FILE"
  chmod 644 "${KEY_FILE}.pub"
  echo "$CHECK Permissions set (private: 600, public: 644)"
else
  echo "$CROSS Key generation failed"
  exit 1
fi

# --- Display public key ---
echo ""
echo "Your public key (copy this to your server or DigitalOcean):"
echo "-----------------------------------------------------------"
cat "${KEY_FILE}.pub"
echo "-----------------------------------------------------------"

# --- Optional: copy to remote server ---
if [ -n "$REMOTE_USER" ]; then
  echo "Copying public key to $REMOTE_USER..."
  if ssh-copy-id -i "${KEY_FILE}.pub" "$REMOTE_USER"; then
    echo "$CHECK Key copied to $REMOTE_USER"
    echo "$CHECK Test with: ssh $REMOTE_USER"
  else
    echo "$CROSS Copy failed — check that $REMOTE_USER is reachable"
  fi
fi

echo ""
echo "Done. Connect with: ssh -i $KEY_FILE user@your-server"
