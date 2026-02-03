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

# neovim config
RUN mkdir -p /root/.config/nvim/lua/plugins

# init.lua - main config
RUN cat > /root/.config/nvim/init.lua << 'EOF'
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = { { import = "plugins" } },
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

require("options")
require("keymaps")
require("autocmds")
EOF

# options.lua
RUN cat > /root/.config/nvim/lua/options.lua << 'EOF'
local opt = vim.opt

-- encoding
opt.encoding = "utf-8"
opt.fileencoding = "utf-8"

-- search
opt.incsearch = true
opt.hlsearch = true
opt.ignorecase = true
opt.smartcase = true

-- appearance
opt.number = true
opt.relativenumber = true
opt.colorcolumn = "81"
opt.wrap = true
opt.showbreak = "↪ "
opt.listchars = { tab = "→ ", eol = "↲", nbsp = "␣", trail = "•", extends = "⟩", precedes = "⟨" }
opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"
opt.scrolloff = 1
opt.fillchars = { vert = " " }
opt.laststatus = 2

-- indentation
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2
opt.expandtab = false
opt.autoindent = true
opt.smartindent = true

-- behavior
opt.backspace = "indent,eol,start"
opt.clipboard = "unnamedplus"
opt.splitbelow = true
opt.splitright = true
opt.visualbell = true
opt.errorbells = false
opt.textwidth = 0
EOF

# keymaps.lua
RUN cat > /root/.config/nvim/lua/keymaps.lua << 'EOF'
local map = vim.keymap.set

-- split navigation
map("n", "<C-h>", "<C-w>h", { desc = "Move to left split" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to below split" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to above split" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right split" })

-- split resizing
map("n", "<C-Left>", ":vertical resize +3<CR>", { silent = true })
map("n", "<C-Right>", ":vertical resize -3<CR>", { silent = true })
map("n", "<C-Up>", ":resize +3<CR>", { silent = true })
map("n", "<C-Down>", ":resize -3<CR>", { silent = true })

-- split orientation toggle
map("n", "<Leader>th", "<C-w>t<C-w>H", { desc = "Change to horizontal split" })
map("n", "<Leader>tk", "<C-w>t<C-w>K", { desc = "Change to vertical split" })

-- tabs
map("n", "<Tab>", "gt", { desc = "Next tab" })
map("n", "<S-Tab>", "gT", { desc = "Previous tab" })
map("n", "<C-t>", ":tabnew<CR>", { silent = true, desc = "New tab" })

-- terminal
map("n", "<Leader>tt", ":vsplit | terminal<CR>", { desc = "Open terminal in vsplit" })

-- toggle invisible chars
map("n", "<Leader>ti", ":set list!<CR>", { desc = "Toggle invisible chars" })

-- strip trailing whitespace
map("n", "<F5>", function()
  local pos = vim.api.nvim_win_get_cursor(0)
  vim.cmd([[%s/\s\+$//e]])
  vim.api.nvim_win_set_cursor(0, pos)
end, { desc = "Strip trailing whitespace" })

-- create file under cursor
map("n", "<Leader>gf", function()
  local file = vim.fn.expand("<cfile>")
  local filepath = vim.fn.expand("%:p:h") .. "/" .. file
  if vim.fn.filereadable(filepath) == 1 then
    vim.cmd("normal! gf")
  else
    vim.fn.system("touch " .. filepath)
    print("File created: " .. filepath)
    vim.cmd("normal! gf")
  end
end, { desc = "Create/go to file under cursor" })

-- clear search highlight
map("n", "<Esc>", ":nohlsearch<CR>", { silent = true })
EOF

# autocmds.lua
RUN cat > /root/.config/nvim/lua/autocmds.lua << 'EOF'
local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

local filetype_settings = augroup("FileTypeSettings", { clear = true })

autocmd("FileType", {
  group = filetype_settings,
  pattern = "make",
  callback = function()
    vim.opt_local.tabstop = 8
    vim.opt_local.softtabstop = 8
    vim.opt_local.shiftwidth = 8
    vim.opt_local.expandtab = false
  end,
})

autocmd("FileType", {
  group = filetype_settings,
  pattern = "yaml",
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true
  end,
})

autocmd("FileType", {
  group = filetype_settings,
  pattern = { "html", "css" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true
  end,
})

autocmd("FileType", {
  group = filetype_settings,
  pattern = "javascript",
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.expandtab = false
  end,
})

autocmd({ "BufNewFile", "BufRead" }, {
  pattern = "*.rss",
  callback = function()
    vim.opt_local.filetype = "xml"
  end,
})
EOF

# plugins
RUN cat > /root/.config/nvim/lua/plugins/init.lua << 'EOF'
return {
  -- colorscheme
  {
    "ellisonleao/gruvbox.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("gruvbox").setup({})
      vim.cmd("colorscheme gruvbox")
    end,
  },

  -- tmux integration
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
  },

  -- fuzzy finder (replaces fzf.vim)
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = "Telescope",
    keys = {
      { "<C-p>", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<C-o>", "<cmd>Telescope git_files<cr>", desc = "Git files" },
      { "<C-f>", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
      { "<Leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<Leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
    },
    config = function()
      require("telescope").setup({
        defaults = {
          file_ignore_patterns = { "node_modules", ".git/" },
        },
      })
    end,
  },

  -- git signs (replaces gitgutter)
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("gitsigns").setup({
        signs = {
          add = { text = "+" },
          change = { text = "~" },
          delete = { text = "_" },
          topdelete = { text = "‾" },
          changedelete = { text = "~" },
        },
      })
    end,
  },

  -- git commands (fugitive)
  {
    "tpope/vim-fugitive",
    cmd = { "Git", "Gdiff", "Gread", "Gwrite" },
    keys = {
      { "<Leader>gc", "<cmd>Git commit %<cr>", desc = "Git commit" },
      { "<Leader>gd", "<cmd>Gdiff<cr>", desc = "Git diff" },
      { "<Leader>gst", "<cmd>Git<cr>", desc = "Git status" },
      { "<Leader>gp", "<cmd>Git push<cr>", desc = "Git push" },
      { "<Leader>gb", "<cmd>Git blame<cr>", desc = "Git blame" },
    },
  },

  -- treesitter for better syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "vim", "vimdoc", "go", "python", "javascript", "typescript", "json", "yaml", "bash" },
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },
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
# Reload tmux.conf from tmux
bind r source-file ~/.tmux.conf

# Remap prefix to Ctrl-Space
unbind C-b
set-option -g prefix C-space
bind-key C-space send-prefix

# Set true colors
set-option -sa terminal-overrides ",xterm*:Tc"

# Enable mouse usage
set -g mouse on

# Set clipboard output to 'system'
set -g set-clipboard external

# Do auto-rename my windows please..
set-option -g allow-rename off

# Auto-set title
set-option -g set-titles on

# Never lag vim
set -sg escape-time 1

# Easier to remember split keys
# Also, open new split in working dir
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'
unbind %

set-window-option -g mode-keys vi
bind-key -T copy-mode-vi 'v' send-keys -X begin-selection
bind-key -T copy-mode-vi 'y' send-keys -X copy-selection-and-cancel
bind-key p paste-buffer

# Switch panes using Alt-arrow
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# Resize panes with Ctrl + arrows, no prefix
bind -n C-Left resize-pane -L 5
bind -n C-Right resize-pane -R 5
bind -n C-Up resize-pane -U 5
bind -n C-Down resize-pane -D 5

# Resize panes with vim keys
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

bind C-s setw synchronize-panes

bind-key -T copy-mode-vi 'C-h' "select-pane -L"
bind-key -T copy-mode-vi 'C-j' "select-pane -D"
bind-key -T copy-mode-vi 'C-k' "select-pane -U"
bind-key -T copy-mode-vi 'C-l' "select-pane -R"
bind-key -T copy-mode-vi 'C-\' "select-pane -l"

# Restore 'clear screen' in bash
bind C-l send-keys 'C-l'

# Several useful settings, ensuring correct colors
# utf8 encoding and a larger history
set -g default-terminal "screen-256color"
set -g history-limit 10000

# Start windows and panes from index 1 instead of 0
set -g base-index 1
setw -g pane-base-index 1

# Theme setup
BLACK="#333333"
DARKGRAY="#0C0C0C"
WHITE="#EEEEEE"
RED="#AA0000"
GREEN="#007700"

set-option -g status on
set-option -g status-position bottom

set -g status-justify centre
set -g status-interval 5
set -gq status-style fg=$BLACK,bg=$WHITE

set -g status-left-length 30
set -gq status-left '█▓▒░#{?client_prefix,#[bg=green][#(whoami)@#(hostname) × #S],[#(whoami)@#(hostname) × #S]}'
set -gq status-left-style dim

set -g status-right-length 70
set -g status-right " #(hostname -I | cut -d ' ' -f 1) [#I:#P] %H:%M ░▒▓█"
set -gq status-right-style dim

set -g window-status-separator ' ■ '
set -gq window-status-current-style fg=$GREEN,bold
set -gq window-status-bell-style fg=$RED,blink
set -gq window-status-activity-style fg=$RED,blink

set -gq window-style fg=$WHITE,bg=$BLACK
set -gq window-status-style fg=$DARKGRAY,bg=$WHITE

set -gq pane-active-border-style fg=$DARKGRAY
set -gq pane-border-style fg=$DARKGRAY,bg=$BLACK

# Colorize when we sync panes in a window
setw -g window-status-current-format '#{?pane_synchronized,#[bg=red],}#I:#W'
setw -g window-status-format '#{?pane_synchronized,#[bg=red],}#I:#W'

# Visual activity
set -g visual-activity on
set -g visual-bell off
set -g visual-silence on
setw -g monitor-activity on
set -g bell-action any

# Mouse wheel scrolling
bind -n WheelUpPane if-shell -F -t = "#{mouse_any_flag}" "send-keys -M" "if -Ft= '#{pane_in_mode}' 'send-keys -M' 'select-pane -t=; copy-mode -e; send-keys -M'"
bind -n WheelDownPane select-pane -t= \; send-keys -M
bind -n C-WheelUpPane select-pane -t= \; copy-mode -e \; send-keys -M
bind -T copy-mode-vi    C-WheelUpPane   send-keys -X halfpage-up
bind -T copy-mode-vi    C-WheelDownPane send-keys -X halfpage-down
bind -T copy-mode-emacs C-WheelUpPane   send-keys -X halfpage-up
bind -T copy-mode-emacs C-WheelDownPane send-keys -X halfpage-down

# Smart pane switching with awareness of vim splits
is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
    | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?'"
bind-key -n 'C-h' if-shell "$is_vim" "send-keys 'C-h'"  "select-pane -L"
bind-key -n 'C-j' if-shell "$is_vim" "send-keys 'C-j'"  "select-pane -D"
bind-key -n 'C-k' if-shell "$is_vim" "send-keys 'C-k'"  "select-pane -U"
bind-key -n 'C-l' if-shell "$is_vim" "send-keys 'C-l'"  "select-pane -R"
bind-key -n 'C-\' if-shell "$is_vim" "send-keys 'C-\\'" "select-pane -l"
EOF

# init chezmoi without repo (local mode)
RUN chezmoi init

# set zsh as default shell for root
RUN chsh -s /bin/zsh root

# cleanup to reduce image size (keep fzf examples for zsh)
RUN rm -rf \
    /var/lib/apt/lists/* \
    /var/cache/apt/* \
    /var/log/* \
    /usr/share/man/* \
    /usr/share/info/* \
    /usr/share/locale/* \
    /tmp/* \
    /root/.cache/* \
    /opt/mise/cache/* \
    && find /usr/share/doc -mindepth 1 ! -path "/usr/share/doc/fzf*" -delete 2>/dev/null || true \
    && find / -name "*.pyc" -delete 2>/dev/null || true \
    && find / -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

WORKDIR /workspace
ENV SHELL=/bin/zsh
ENV TERM=xterm-256color

CMD ["/bin/zsh"]
