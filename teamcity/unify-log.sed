# remove download lines
/ Downloading: /d;
/ Downloaded: /d;

# remove timestamps
s#^\[..:..:..\]##;

# unify checkout dir
s#/[0-9a-zA-Z_/]*/app/work/[0-9a-f]\{4,16\}#_TEAMCITY_BUILD_CHECKOUTDIR_#g#;

# liquibase unifications
s# in [[:digit:]]*ms# in X_ms#g;
s#::[[:digit:]]\{4,16\}-[[:digit:]]\{1,5\}::#_LIQUIBASE_HASH_#g;
s#: ServerSession([[:digit:]]\{4,12\})#ServerSession(_LIQUIBASE_SERVER_SESSION_)#g;
