FROM alpine

#based on https://github.com/moigagoo/nimage/
RUN apk add --no-cache g++ curl tar xz libgcrypt git
RUN mkdir -p /nim; \
    curl -sL "https://nim-lang.org/download/nim-1.0.0-linux_x64.tar.xz" \
    |tar -xJ --strip-components=1 -C /nim; \
    cd /nim; sh build.sh; \
    ln -s `pwd`/bin/nim /bin/nim; \
    bin/nim c koch; \
    ./koch tools; \
    ln -s `pwd`/bin/nimble /bin/nimble; \
    ln -s /usr/lib/libgcrypt.so.20 /usr/lib/libgcrypt.so

VOLUME "/challenge"
WORKDIR "/challenge"
RUN nimble install libgcrypt -y
CMD ["nim", "-d:release", "--threads:on", "-o:padding-alpine", "--passc:-flto", "c", "padding.nim"]
#CMD ["nim", "-d:release", "--stackTrace:on", "--profiler:on", "--threads:on", "-o:padding-alpine", "--passc:-flto", "c", "padding.nim"]
