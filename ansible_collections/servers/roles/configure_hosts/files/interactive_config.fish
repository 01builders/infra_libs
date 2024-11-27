status --is-interactive; and begin
    set fish_greeting # Disable greeting

    if type -q atuin
        atuin init fish --disable-up-arrow | source
    end

    if type -q batcat
        alias cat 'batcat --pager=never'
        set -x BAT_THEME "Catppuccin Mocha"
    end

    if type -q dysk
        alias dysk='dysk --filter "type <> nfs4"'
    end

    if type -q eza
        alias ll='eza -l --icons=auto --group-directories-first' 2>/dev/null
        alias l.='eza -d .*' 2>/dev/null
        alias ls='eza' 2>/dev/null
        alias l1='eza -1'
    end

    if type -q fdfind
        alias find='fd' 2>/dev/null
    end

    if type -q fzf
        # catppuccin mocha - https://github.com/catppuccin/fzf
        set -Ux FZF_DEFAULT_OPTS "\
        --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
        --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
        --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
    end

    if type -q git
        abbr --add --global -- ga 'git add'
        abbr --add --global -- gaa 'git add --all'
        abbr --add --global -- gb 'git branch'
        abbr --add --global -- gbd 'git branch --delete --force'
        abbr --add --global -- gcfd 'git clean -fd'
        abbr --add --global -- gcm 'git commit -m'
        abbr --add --global -- gcma 'git commit --amend --no-edit'
        abbr --add --global -- gcmf 'git commit --fixup'
        abbr --add --global -- gco 'git checkout'
        abbr --add --global -- gcob 'git checkout -b'
        abbr --add --global -- glol 'git log --graph --decorate --pretty=oneline --abbrev-commit --topo-order'
        abbr --add --global -- glola 'git log --graph --decorate --pretty=oneline --abbrev-commit --topo-order --all'
        abbr --add --global -- gm 'git merge --no-ff'
        abbr --add --global -- gpl 'git pull'
        abbr --add --global -- gplom 'git pull origin main'
        abbr --add --global -- gpr 'git reset --hard'
        abbr --add --global -- gps 'git push'
        abbr --add --global -- gpsf 'git push --force'
        abbr --add --global -- gpt 'git push --tags'
        abbr --add --global -- gri 'git rebase --interactive HEAD'
        abbr --add --global -- gs 'git status --short'
    end

    if type -q kubectl
        abbr --add --global -- k 'kubectl'
        abbr --add --global -- kdpf 'kubectl delete pod --force --grace-period 0'
    end

    if type -q rg
        alias grep='rg' 2>/dev/null
        alias egrep='rg' 2>/dev/null
        alias fgrep='rg -F' 2>/dev/null
        alias xzgrep='rg -z' 2>/dev/null
        alias xzegrep='rg -z' 2>/dev/null
        alias xzfgrep='rg -z -F' 2>/dev/null
    end

    if type -q starship
        set -x STARSHIP_CONFIG ~/.config/starship.toml
        starship init fish | source
    end

    if type -q zoxide
        zoxide init --cmd cd fish | source
    end
end
