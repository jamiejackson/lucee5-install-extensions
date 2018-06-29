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

ENV DEPLOY_DIR=/opt/lucee/server/lucee-server/deploy

# drop *.lex into deploy directory
COPY --from=redis-extension-builder /tmp/extension-redis-single.lex "${DEPLOY_DIR}/"

COPY warmup_extension.sh ./tmp/
RUN chmod a+x ./tmp/warmup_extension.sh \
 && ./tmp/warmup_extension.sh server '43AC6017-4EF7-4F14-89AB253C347E6A8F' \
 && rm ./tmp/warmup_extension.sh
