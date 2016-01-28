#!/bin/bash

#
# Generate IDEA migration xml based on rename.txt file
#

NAME="${1?'please specify migration name'}"
shift
DESCRIPTION="$@"

function generateXml() {
cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<migrationMap>
  <name value="$NAME" />
  <description value="" />
EOF

sed -f - rename.txt << "EOF"
/^[[:alnum:]_\.]\+\.=[[:alnum:]_\.]\+[[:alnum:]_]*/{
s#^\([[:alnum:]_\.]\+\)\.=\([[:alnum:]_\.]\+\)\.\([^.]\+\)$#<entry oldName="\2.\3" newName="\1.\3" type="class"/>##;
s#^\([[:alnum:]_\.]\+\)\.=\([[:alnum:]_\.]\+\)\.$#<entry oldName="\2" newName="\1" type="package" recursive="true"/>##;
s:^:  :;
}
/^#/d;
/^$/d;
EOF

cat <<EOF
</migrationMap>
EOF
}

cat rename.txt | generateXml #>$NAME.xml
