# dotfiles
My setup

Usage:

* Edit `dot_zshrc`
* Run scripts - `chezmoi apply`
* Run `chezmoi cd` and commit and push changes

Interesting files:

* `run_once_before_install-packages-darwin.sh.tmpl` contains homebrew packages which are installed on `chezmoi apply`

Setup on a new machine:
`chezmoi init --apply dewinterjack`
