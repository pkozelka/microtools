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