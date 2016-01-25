# Java utilities

## Refactor

`refactor.sh` is a simple refactoring command performing bulk renames of java classes.

It reads file `rename.txt` which contains java classname mappings, one per line, in the following form:

```
fully.qualified.new.ClassName=f.q.OldName
```

This command performs:
- file renames (using SCM if requested)
- fix of package name
- fix of all references (typically imports)

Future features may include:
- automatic rename of co-named unit tests
- remove useless imports
- add newly required imports
