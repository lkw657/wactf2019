FROM alpine

RUN apk add libc6-compat libgcrypt zlib

RUN adduser -s /bin/false -H -D challenge

WORKDIR /challenge
COPY ./padding-alpine /challenge
RUN chown -R challenge:challenge /challenge

USER challenge
EXPOSE 1337
CMD ["/challenge/padding-alpine", "1337"]
