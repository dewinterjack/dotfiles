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

Install Setapp apps:

* Open Setapp desktop & login
* On the **Favorites** page you can press **Install all**

<img width="920" alt="image" src="https://github.com/dewinterjack/dotfiles/assets/17269242/14c67263-e08f-49d3-bedc-bd116a7dd653">


If you don't want everything from your favorites to be installed you can use **Quick installation** to select only what you want to install.



<img width="787" alt="image" src="https://github.com/dewinterjack/dotfiles/assets/17269242/99b1695b-48d5-452b-9c50-cdcde41b47ca">
