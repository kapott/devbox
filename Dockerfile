FROM alpine:3.21 AS base

RUN apk add --no-cache \
    bash \
    curl \
    git \
    fzf \
    ripgrep \
    zsh \
    tmux \
    neovim \
    chezmoi \
    # build essentials for mise/plugins
    build-base \
    # needed for python
    libffi-dev \
    openssl-dev \
    zlib-dev \
    readline-dev \
    sqlite-dev \
    bzip2-dev \
    xz-dev \
    # needed for node
    linux-headers

# install mise
RUN curl https://mise.run | sh && \
    mv /root/.local/bin/mise /usr/local/bin/mise

# setup mise globally
ENV MISE_DATA_DIR=/opt/mise
ENV MISE_CACHE_DIR=/opt/mise/cache
ENV PATH="/opt/mise/shims:${PATH}"
SHELL ["/bin/bash", "-c"]

# install runtimes
RUN mise use -g go@latest python@latest node@lts && \
    mise reshim

# bootstrap lazy.nvim
RUN git clone --filter=blob:none --branch=stable \
    https://github.com/folke/lazy.nvim.git \
    /root/.local/share/nvim/lazy/lazy.nvim

# minimal lazy.nvim bootstrap config
RUN mkdir -p /root/.config/nvim/lua && \
    cat > /root/.config/nvim/init.lua << 'EOF'
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  defaults = { lazy = true },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip", "matchit", "matchparen", "netrwPlugin",
        "tarPlugin", "tohtml", "tutor", "zipPlugin",
      },
    },
  },
})
EOF

RUN mkdir -p /root/.config/nvim/lua/plugins && \
    cat > /root/.config/nvim/lua/plugins/init.lua << 'EOF'
return {
  -- add plugins here
}
EOF

# zsh config
RUN cat > /root/.zshrc << 'EOF'
export PATH="/opt/mise/shims:$PATH"
eval "$(mise activate zsh)"

# fzf
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh

# basic prompt
PROMPT='%F{blue}%~%f %# '

# aliases
alias vim=nvim
alias vi=nvim
alias lg=lazygit
EOF

# tmux config
RUN cat > /root/.tmux.conf << 'EOF'
set -g default-terminal "tmux-256color"
set -ag terminal-overrides ",xterm-256color:RGB"
set -g mouse on
set -g base-index 1
setw -g pane-base-index 1
EOF

# init chezmoi without repo (local mode)
RUN chezmoi init

# set shell
RUN sed -i 's|/bin/ash|/bin/zsh|' /etc/passwd

WORKDIR /workspace
ENV SHELL=/bin/zsh
ENV TERM=xterm-256color

CMD ["/bin/zsh"]
