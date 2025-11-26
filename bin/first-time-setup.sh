#!/bin/bash

echo "==================================="
echo "First Time Setup - Devbox Migration"
echo "==================================="

# Install Devbox if not already installed
if ! command -v devbox &>/dev/null; then
  echo "Installing Devbox..."
  curl -fsSL https://get.jetpack.io/devbox | bash

  # Add Devbox to PATH for current session
  export PATH="$HOME/.local/bin:$PATH"

  # Add to shell profile if not already there
  if [ -n "$ZSH_VERSION" ]; then
    SHELL_PROFILE="${ZDOTDIR:-$HOME}/.zshrc"
  elif [ -n "$BASH_VERSION" ]; then
    SHELL_PROFILE="$HOME/.bashrc"
  else
    SHELL_PROFILE="$HOME/.profile"
  fi

  if ! grep -q "/.local/bin" "$SHELL_PROFILE" 2>/dev/null; then
    echo "" >>"$SHELL_PROFILE"
    echo "# Devbox installation" >>"$SHELL_PROFILE"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >>"$SHELL_PROFILE"
    echo "Added Devbox to PATH in $SHELL_PROFILE"
  fi
else
  echo "Devbox is already installed"
fi

# Note: lastpass-cli is now installed via Devbox/Nix packages
# No need for separate Homebrew installation

# Initialize Devbox shell
echo ""
echo "Initializing Devbox environment..."
echo "This will download and install all required packages."
echo ""

# Install packages and enter shell
devbox install

echo ""
echo "==================================="
echo "Setup Complete!"
echo "==================================="
echo ""
echo "To enter the development environment, run:"
echo "  devbox shell"
echo ""
echo "Or to run a single command:"
echo "  devbox run <command>"
echo ""
