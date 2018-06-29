#!/usr/bin/env bash

# ./warmup_extension.sh <(server|web)> '<extension_id>'
# example:
# ./warmup_extension.sh server '43AC6017-4EF7-4F14-89AB253C347E6A8F'

EXTENSION_TYPE=$1
EXTENSION_ID=$2

SERVER_CONTEXT=/opt/lucee/server/lucee-server/context
WEB_CONTEXT=/opt/lucee/web
DEPLOY_DIR=/opt/lucee/server/lucee-server/deploy

echo "give lucee a password of 'password'"
setPassword () { 
  sed -i.orig 's/salt="[^"]*"/hspw="428bbc17a56cc9637c22db3767377299aff3526ec851a0994cf9c3bb7385155f" salt="4FDA588E-318A-445C-898736AA1F229A69"/' $1
}
setPassword $SERVER_CONTEXT/lucee-server.xml
setPassword $WEB_CONTEXT/lucee-web.xml.cfm

echo "create a test app"
mkdir -p /var/www/test_app

cat > /var/www/test_app/index.cfm <<EOF
<cfscript>
  param name="url.type" default="";
  param name="url.extensionId" default="";
  serverAdmin = new Administrator(url.type, "password");
  extensions = serverAdmin.getExtensions();
  dump(var=extensions, format="text");
  if ( queryExecute("select id from extensions where id = '#url.extensionId#'", {}, {dbtype="query"} ).recordCount == 0) throw();
</cfscript>
EOF

echo "warmup tomcat to trigger extension installation"
catalina.sh start
echo "wait until extension is installed"
until $(curl --output /dev/null --silent --head --fail "http://localhost:8888/test_app/?type=${EXTENSION_TYPE}&extensionId=${EXTENSION_ID}"); do
  printf '.'
  sleep 1
done
catalina.sh stop

echo "cleanup workarounds"
mv $SERVER_CONTEXT/lucee-server.xml.orig $SERVER_CONTEXT/lucee-server.xml
mv $WEB_CONTEXT/lucee-web.xml.cfm.orig $WEB_CONTEXT/lucee-web.xml.cfm
rm -rf /var/www/test_app
