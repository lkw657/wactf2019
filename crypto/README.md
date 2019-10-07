# Files
* `common/crypto.nim` Shitty partial high level wrapper around gcrypt + padding
* `common/challenge.nim` logging/exception handling + threading/serving
* `common/zlib.nim` from https://github.com/krux02/zip/blob/fix-version-mismatch/zip/zlib.nim since the official one has version issues
* `padding.nim` padding oracle challenge

A string for the padding oracle attack is
```
1f8b0800b71f9b5d00ff6310e0569d58b1354b3d3d63a3d99d1b7dab1c5a739f084a6b484b2d5d31bfa7547d43ace85469cb80ab77235f9c2cd1ffbefa40a0d7891d05af5fdd5c5979f4b25d75f7e7f3001a9ee0c142000000
```

format is hex(gzip('\x00\x10' || ciphertext || iv))
\x00\x10 (16 as a 2 byte int) represents the block size of the AES cipher

# Dependencies
* gcrypt
* nim
* gcrypt nim bindings `nimble install libgcrypt`

# Running
compile with `nim c --threads:on padding.nim`
run with `./padding <port>`

run solution with `python3 solvePadding.py <port>`

## Docker
compile.dockerfile will compile the challenge on alpine because I can't be bothered messing around with cross compiling with musl. or trying to make alpine (fully) gcc compatable
### Recompile on alpine
```
docker build -f compile.dockerfile -t padding-compile .
docker run -v `pwd`:/challenge -it padding-compile
```
### Run challenge
```
docker build -t padding .
sudo docker run -it -p 1337:1337 padding
```
