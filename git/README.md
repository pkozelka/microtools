# GIT utilities


## Fix email address of committer and author

Inspired by http://serverfault.com/questions/12373/how-do-i-edit-gits-history-to-correct-an-incorrect-email-address-name

Synopsis:

```
./git-change-email.sh <old_email> <new_email>
```


## List pull-requests created by Atlassian Stash

```
./astash-ls-pr.sh
```


## Show mainline of commits

Generates json view of main commit line

```
./git-mainline.sh 
```


## List obsolete local branches (gone)

Lists branches that lost their remote counterparts.

```
ln -s $HOME/github.com/microtools/git/git-gone.sh $HOME/bin/git-gone
git gone
git gone | xargs git branch -d
```
