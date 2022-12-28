#!/bin/sh

curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh

# Install Powerline Fonts
git clone https://github.com/powerline/fonts.git --depth=1
cd fonts || exit
./install.sh
cd ..
rm -rf fonts