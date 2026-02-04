FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
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

# Create dev user (UID will be changed at runtime)
RUN useradd -m -s /bin/bash dev \
    && echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install chezmoi
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin

# Switch to dev for dotfiles setup
USER dev
WORKDIR /home/dev

ENV TERM=xterm-256color

RUN chezmoi init \
    --promptString name="Dev Container" \
    --promptString email="dev@container.local" \
    --promptString "window manager (kde/gnome/xfce/i3/sway/hyprland/none)"="none" \
    https://github.com/kapott/dotfiles.git \
    && chezmoi apply

RUN vim +PluginInstall +qall

# Back to root for entrypoint
USER root
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /home/dev/workspace
ENTRYPOINT ["/entrypoint.sh"]
