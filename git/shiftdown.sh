#!/bin/sh

# rewrites all commits, makes files appear inside "PREFIX" directory since beginning (changes all hashes!)


PREFIX=${1?'tell prefix!'}

# usage: 
# git filter-branch --tree-filter $PWD/shiftdown.sh

files=`ls -1`
[ -f .gitignore ] && files="$files .gitignore"
if [ -s /tmp/xxx-z ]; then
mkdir -p .result \
&& mv $files .result/ \
&& mv .result "$PREFIX"
else
        true
fi
