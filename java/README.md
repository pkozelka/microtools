# Java utilities

## Refactor

`refactor.sh` is a simple refactoring command performing bulk renames of java classes.

It reads file `rename.txt` which contains java classname mappings, one per line, in the following forms:

```
fully.qualified.new.ClassName=f.q.OldName
just.a.package.new.=the.package.new.
package.new.=package.old.UnchangedClassName
```

Notice the symbols ending with dot - these express just package name.

* first form moves the class to a different package and also changes its name
* second form changes package of multiple classes
* third form moves the class to a new package

This command performs:
- file renames (using SCM if requested)
- fix of package name
- fix of all references (typically imports)

Future features may include:
- automatic rename of co-named unit tests
- remove useless imports
- add newly required imports
