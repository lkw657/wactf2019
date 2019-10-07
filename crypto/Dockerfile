FROM alpine

RUN apk add libc6-compat && apk add libgcrypt
#RUN adduser -S -h /challenge challenge

#USER challenge

WORKDIR /challenge
COPY ./padding-alpine /challenge

EXPOSE 1337
CMD ["/challenge/padding-alpine", "1337"]
