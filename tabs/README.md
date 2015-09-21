# Tabs

## TAB throttler

### Purpose

This tool is meant for incremental removal of spaces from the source code.

### The story

The team decided to switch its coding style. One part of this switch was, replacing `TAB`-indentation with space-indentation.

At the same time, we do not want to bulk-reindent all sources, because that would make it much harder to find out who is the last author of every reindented line.

So the resolution is:

- do not allow new `TAB` character to appear in the source code
- ideally, make sure people fix indentation on lines that they modify for other purposes
- make a list of files that contains `TAB`s.

### Usage

On your **CI server**, add something like this script at the start of your *all branch build* job:

```sh
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
case "$CURRENT_BRANCH" in
master|maintenance-*)
    echo "skipping TAB check in maintenance branch '$CURRENT_BRANCH'"
#develop);;
    # TODO maybe ... update tab-tolerance.txt automatically?
    # $HOME/github.com/microtools/tabs/throttler.sh list | grep -v '/target/' >tab-tolerance.txt
*)
    # check if TAB counts are within per-file limits
    $HOME/github.com/microtools/tabs/throttler.sh check tab-tolerance.txt
esac
```

Therefore, builds prepared in any branch that can merge to your, say, `develop` branch will be checked against tolerated TAB counts specified in the `tab-tolerance.txt` file.

**On commandline**

As a user elevated enough to push directly to your `develop` branch, you shoud prepare and commit the `tab-tolerance.txt` file:
```sh
$HOME/github.com/microtools/tabs/throttler.sh list | grep -v '/target/' >tab-tolerance.txt
git add tab-tolerance.txt
git commit -m 'defined tab-tolerance from the current state' tab-tolerance.txt
```

During time, the number of TABs will become smaller and smaller; it's useful to occassionally reduce the tolerance to ensure that TABs won't return again.

```sh
git add tab-tolerance.txt
git commit -m 'updated tab-tolerance from the current state' tab-tolerance.txt
```


### Makefile fragment

To make things convenient, following can be added to your project `Makefile`:

```Makefile
## TABS THROTLER
tt-download-newer-throttler:
	mkdir -p bin
	cp -a "$(HOME)/github.com/microtools/tabs/throttler.sh" "bin/tabs-throttler.sh" ||\
	wget -O "bin/tabs-throttler.sh" "https://raw.githubusercontent.com/pkozelka/microtools/master/tabs/throttler.sh"
	chmod +x "bin/tabs-throttler.sh"
	git add "bin/tabs-throttler.sh"
	git commit -m 'tabs-throttler upgraded' "bin/tabs-throttler.sh"

tt-update:
	git checkout tab-tolerance.txt
	bin/tabs-throttler.sh update tab-tolerance.txt >.git/tt-message
	git add tab-tolerance.txt
	git commit -F .git/tt-message tab-tolerance.txt

tt-check:
	# run this from CI
	bin/tabs-throttler.sh check tab-tolerance.txt
```
