#!/bin/bash
# http://serverfault.com/questions/12373/how-do-i-edit-gits-history-to-correct-an-incorrect-email-address-name

OLD_EMAIL=${1?'param #1: specify old email'}
NEW_EMAIL=${2?'param #2: specify new email'}

git filter-branch --env-filter '
	OLD_EMAIL="'$OLD_EMAIL'"
	NEW_EMAIL="'$NEW_EMAIL'"
	[ "$GIT_AUTHOR_EMAIL" = "$OLD_EMAIL" ] && GIT_AUTHOR_EMAIL="$NEW_EMAIL"
	[ "$GIT_COMMITTER_EMAIL" = "$OLD_EMAIL" ] && GIT_COMMITTER_EMAIL="$NEW_EMAIL"
	true
	' HEAD
