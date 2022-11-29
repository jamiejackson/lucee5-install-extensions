#!/usr/bin/env bash

set -e

# ./warmup_extension.sh <(server|web)> '<extension_id>'
# example:
# ./warmup_extension.sh server '43AC6017-4EF7-4F14-89AB253C347E6A8F'

EXTENSION_TYPE=$1
EXTENSION_ID=$2
EXTENSION_VERSION=$3

SERVER_CONTEXT=/opt/lucee/server/lucee-server/context
WEB_CONTEXT=/opt/lucee/web
DEPLOY_DIR=/opt/lucee/server/lucee-server/deploy

setPassword () {
  type=$1
  pathname=$2
  echo "## setting $type password"
  originalTag=$(grep -Po "<cfLuceeConfiguration[^>]*>" $pathname)
  if [ "$type" == "web" ]; then
    original_web_tag=$originalTag
    version='4.5'
  else
    original_server_tag=$originalTag
    version='5.2'
  fi
  new_tag='<cfLuceeConfiguration hspw="428bbc17a56cc9637c22db3767377299aff3526ec851a0994cf9c3bb7385155f" salt="4FDA588E-318A-445C-898736AA1F229A69" version="'$version'"\>'
  echo "##  BEFORE: $(grep salt $pathname)"
  sed -i'' "s/<cfLuceeConfiguration[^>]*>/$new_tag/" $pathname
  echo "##  AFTER: $(grep salt $pathname)"
}
resetPassword() {
  echo "## resetting $type password"
  type=$1
  pathname=$2
  if [ "$type" == "web" ]; then
    originalTag=$original_web_tag
  else
    originalTag=$original_server_tag
  fi
  echo "##  reset to original tag: $originalTag"
  echo "##  BEFORE: $(grep salt $pathname)"
  sed -i'' "s/<cfLuceeConfiguration[^>]*>/$originalTag/" $pathname
  echo "##  AFTER: $(grep salt $pathname)"
}

echo "give lucee a password of 'password'"
setPassword server $SERVER_CONTEXT/lucee-server.xml
setPassword web $WEB_CONTEXT/lucee-web.xml.cfm

echo "create a test app"
mkdir -p /var/www/wwwroot/test_app

cat > /var/www/wwwroot/test_app/Application.cfc <<EOF
component { 
  this.ormenabled = true;
}
EOF

cat > /var/www/wwwroot/test_app/index.cfm <<EOF
<cfscript>
  param name="url.type" default="";
  param name="url.extensionId" default="";
  param name="url.version" default="";
  serverAdmin = new Administrator(url.type, "password");
  extensions = serverAdmin.getExtensions();
  // dump(var=extensions, format="text");
  if ( url.extensionId == 'FAD1E8CB-4F45-4184-86359145767C29DE' ) {
    try {
     ormReload();
    } catch (any e) {
      sleep 30;
      ormReload();
    }
  }

  sql = "select * from extensions where id = '#url.extensionId#'";
  if (len(url.version)) {
    sql &= " and version = '#url.version#'";
  }

  extension = queryExecute(
    sql,
    {},
    {dbtype="query"}
  );

  // dump(extension);

  // throw an error when the extension isn't found.
  // that will cause curl to fail and the loop to retry
  if (extension.recordCount == 0) {
    throw();
  }
</cfscript>
EOF

echo "warmup tomcat to trigger extension installation"
catalina.sh start
echo "wait until extension is installed"
until $(curl --output /dev/null --silent --head --fail "http://localhost:8888/test_app/?type=${EXTENSION_TYPE}&extensionId=${EXTENSION_ID}&version=${EXTENSION_VERSION}"); do
  printf '.'
  sleep 1
done
echo ""
catalina.sh stop

echo "cleanup workarounds"
resetPassword server $SERVER_CONTEXT/lucee-server.xml
resetPassword web $WEB_CONTEXT/lucee-web.xml.cfm
rm -rf /var/www/wwwroot/test_app
