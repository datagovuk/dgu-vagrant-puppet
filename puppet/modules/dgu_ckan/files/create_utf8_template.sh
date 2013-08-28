#!/bin/sh

TMPL_NAME="template_utf8"

cat << EOF | psql -d postgres -q
CREATE DATABASE $TMPL_NAME WITH template = template0 ENCODING='UTF8';
UPDATE pg_database SET datistemplate = TRUE WHERE datname = '$TMPL_NAME';
EOF

