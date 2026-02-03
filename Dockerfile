FROM debian:trixie-slim AS base

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    ca-certificates \
    git \
    fzf \
    ripgrep \
    zsh \
    tmux \
    neovim \
    # build essentials for mise/python
    build-essential \
    libffi-dev \
    libssl-dev \
    zlib1g-dev \
    libreadline-dev \
    libsqlite3-dev \
    libbz2-dev \
    liblzma-dev \
    && rm -rf /var/lib/apt/lists/*

# install chezmoi
RUN curl -sfL https://git.io/chezmoi | sh -s -- -b /usr/local/bin

# install mise
RUN curl https://mise.run | sh && \
    mv /root/.local/bin/mise /usr/local/bin/mise

# setup mise globally
ENV MISE_DATA_DIR=/opt/mise
ENV MISE_CACHE_DIR=/opt/mise/cache
ENV PATH="/opt/mise/shims:${PATH}"

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
[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
[ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh

# basic prompt
PROMPT='%F{blue}%~%f %# '

# aliases
alias vim=nvim
alias vi=nvim
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

# set zsh as default shell for root
RUN chsh -s /bin/zsh root

# cleanup to reduce image size
RUN rm -rf \
    /var/lib/apt/lists/* \
    /var/cache/apt/* \
    /var/log/* \
    /usr/share/doc/* \
    /usr/share/man/* \
    /usr/share/info/* \
    /usr/share/locale/* \
    /tmp/* \
    /root/.cache/* \
    /opt/mise/cache/* \
    && find / -name "*.pyc" -delete 2>/dev/null || true \
    && find / -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

WORKDIR /workspace
ENV SHELL=/bin/zsh
ENV TERM=xterm-256color

CMD ["/bin/zsh"]
