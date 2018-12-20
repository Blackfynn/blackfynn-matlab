#!/bin/bash

APT_PACKAGES="libxt6"

#### Setup Environment
cat <<EOF > /etc/vim/vimrc.local
colorscheme desert
EOF

cat <<'EOF' >> /etc/profile
export VISUAL=vim
export EDITOR="\\$VISUAL"
export LD_LIBRARY_PATH="\\$LD_LIBRARY_PATH:/usr/local/MATLAB/R2018a/runtime/glnxa64:/usr/local/MATLAB/R2018a/bin/glnxa64:/usr/local/MATLAB/R2018a/sys/os/glnxa64:/usr/local/MATLAB/R2018a/sys/java/jre/glnxa64/jre/lib/amd64/native_threads:/usr/local/MATLAB/R2018a/sys/java/jre/glnxa64/jre/lib/amd64/server:/usr/local/MATLAB/R2018a/sys/java/jre/glnxa64/jre/lib/amd6"
export PATH="\\$PATH:/usr/local/MATLAB/R2018a/runtime/glnxa64:/usr/local/MATLAB/R2018a/bin:/usr/local/MATLAB/R2018a/bin/glnxa64:/usr/local/MATLAB/R2018a/sys/os/glnxa64:/usr/local/MATLAB/R2018a/sys/java/jre/glnxa64/jre/lib/amd64/native_threads:/usr/local/MATLAB/R2018a/sys/java/jre/glnxa64/jre/lib/amd64/server:/usr/local/MATLAB/R2018a/sys/java/jre/glnxa64/jre/lib/amd6"
EOF

cat <<'EOF' > /home/vagrant/.bash_aliases
export LS_COLORS="di=1:fi=0:ln=31:pi=5:so=5:bd=5:cd=5:or=31:mi=0:ex=35:*.rpm=90"
export CLICOLOR=1
export LANG="en_US.utf8"
export PS1="\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\]\[\033[00m\]$ "
EOF

#### Install software
apt-get update && apt-get install -y ${APT_PACKAGES}

apt-get -y autoremove
