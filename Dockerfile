FROM debian:trixie-slim

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Core packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    sudo \
    ca-certificates \
    vim \
    fzf \
    ripgrep \
    zoxide \
    tmux \
    && rm -rf /var/lib/apt/lists/*

# Create dev user
RUN useradd -m -s /bin/bash dev \
    && echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install chezmoi
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin

# Switch to dev user
USER dev
WORKDIR /home/dev

# Set TERM for colors
ENV TERM=xterm-256color

# Init dotfiles with default values (no prompts)
RUN chezmoi init \
    --promptString name="Dev Container" \
    --promptString email="dev@container.local" \
    --promptString "window manager (kde/gnome/xfce/i3/sway/hyprland/none)"="none" \
    https://github.com/kapott/dotfiles.git \
    && chezmoi apply

# Install Vundle plugins
RUN vim +PluginInstall +qall

# Default workspace
WORKDIR /home/dev/workspace

CMD ["/bin/bash"]
