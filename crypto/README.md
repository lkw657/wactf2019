# Files
* `common/crypto.nim` Shitty partial high level wrapper around gcrypt + padding
* `common/challenge.nim' logging/exception handling + threading/serving
* `padding.nim` padding oracle challenge

A string for the padding oracle attack is
```
00100b259178b56a276768b136dcd88eaa40856de4111b281b1aa5a89f8c7527b05d15951b3950d5dd59e8c9742ff7abc0514ac8b870ebead9a979c5d33e7b8bf3cf
```

# Dependencies
* gcrypt
* nim
* gcrypt nim bindings `nimble install libgcrypt`
solvePadding.py
* python3
* https://github.com/arthaud/python3-pwntools

# Running
compile with `nim c --threads:on padding.nim`
run with `./padding <port>`

run solution with `python3 solvePadding.py <port>`

# Docker
compile.dockerfile will compile the challenge on alpine because I can't be bothered messing around with cross compiling with musl. or trying to make alpine (fully) gcc compatable
## Recompile on alpine
```
docker build -f compile.dockerfile -t padding-compile .
docker run -v `pwd`:/challenge -it padding-compile
```
## Run challenge
```
docker build -t padding .
sudo docker run -it -p 1337:1337 padding
```
