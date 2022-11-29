# Build Redis-Single Extension from Source
FROM kmindi/openjdk-ant-docker as redis-extension-builder

RUN apt-get update && apt-get install -y git

RUN git clone https://github.com/markussackmann/extension-redis-single.git \
  && cd extension-redis-single \
  && ant modern \
  && cp /extension-redis-single/dist/modern/extension-redissingle*.lex \
    /tmp/extension-redis-single.lex

# Use Lucee Container
FROM lucee/lucee52:latest

WORKDIR /

ENV DEPLOY_DIR=/opt/lucee/server/lucee-server/deploy

COPY warmup_extension.sh ./tmp/
RUN chmod a+x ./tmp/warmup_extension.sh

# install the redis extension we built in the first stage
COPY --from=redis-extension-builder /tmp/extension-redis-single.lex "${DEPLOY_DIR}/"
RUN echo "~=%# install redis extension #%=~" \
 && ./tmp/warmup_extension.sh server '43AC6017-4EF7-4F14-89AB253C347E6A8F'

# install cfspreadsheet
RUN echo "~=%# install cfspreadsheet extension #%=~" \
  && cd $DEPLOY_DIR && { curl -O https://raw.githubusercontent.com/Leftbower/cfspreadsheet-lucee-5/master/cfspreadsheet-lucee-5.lex ; cd -; } \
  && ./tmp/warmup_extension.sh server '037A27FF-0B80-4CBA-B954BEBD790B460E'

# needs a warmup because this extension doesn't fully install until an orm function is actually executed
RUN echo "~=%# warm up hibernate extension #%=~" \
  && ./tmp/warmup_extension.sh server 'FAD1E8CB-4F45-4184-86359145767C29DE'
