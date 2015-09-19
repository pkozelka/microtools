# Maven companions for Linux

Files

* [`mwn.sh`](https://github.com/pkozelka/microtools/blob/master/maven/mwn.sh) - [Colorization](#colorization), [Maven Workspaces](#maven-workspaces)
* [`.bash_mvn_completion`](https://github.com/pkozelka/microtools/blob/master/maven/.bash-completion-for-maven) - bash completion for Maven

## mwn

File: [`mwn.sh`](https://github.com/pkozelka/microtools/blob/master/maven/mwn.sh)

* colorizes the console output of Maven
* launches Maven with different environment and workspace

**Configuration**

```
cd $HOME/bin # we assume that ~/bin is on PATH
ln -s $HOME/github.com/microtools/maven/mwn.sh mwn
# alternative:
alias mwn='$HOME/github.com/microtools/maven/mwn.sh'
```

**Usage**

Type `mwn` instead of `mvn` to get the new behavior.
The `mvn` command remains unchanged for the cases where you need original behaviour.

### Colorization

currently helps to emphasize

* goal/mojo headings
* module headings
* errors and warnings
* failed modules
* surefire results
* nested executions

**Credits**

* http://blog.blindgaenger.net/colorize_maven_output.html
* http://johannes.jakeapp.com/blog/category/fun-with-linux/200901/maven-colorized
* Martin Frýdl
* Petr Kozelka (colorization of nested executions)

### Maven Workspaces

Allows each project to be built with different environment, which in particular lets you:

* specify to use different JDK or Maven version
* work with different `settings.xml`
* use different **local maven repository**

## Bash completion for Maven

File: [`.bash_mvn_completion`](https://github.com/pkozelka/microtools/blob/master/maven/.bash-completion-for-maven)

**Configuration**

```
echo 'source $HOME/github.com/microtools/maven/.bash_mvn_completion' >>$HOME/.bashrc
```

**Credits**

* https://github.com/juven/maven-bash-completion
* https://devmanual.gentoo.org/tasks-reference/completion/index.html



