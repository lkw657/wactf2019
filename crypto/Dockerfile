FROM alpine

RUN apk add libc6-compat libgcrypt zlib
RUN adduser -S -h /challenge challenge

USER challenge

WORKDIR /challenge
COPY ./padding-alpine /challenge

EXPOSE 1337
CMD ["/challenge/padding-alpine", "1337"]
