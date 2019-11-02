# Files
* `common/crypto.nim` Shitty partial high level wrapper around gcrypt + padding
* `common/challenge.nim` logging/exception handling + threading/serving
* `common/zlib.nim` from https://github.com/krux02/zip/blob/fix-version-mismatch/zip/zlib.nim since the official one has version issues
* `padding.nim` padding oracle challenge

strings for the padding oracle attack are (last has flag)
```
1f8b08002c26bc5d00ff6310b0d29821639f21f526ec6cc1a41733ec2acface30b5be7dcd46f79704f22e7a63ade1332322f36ae147a1cd2f368be93d3fb6d005980bba932000000
1f8b08006326bc5d00ff6310e88ebc724ee362fed2f84782d67fef33702ca9a93995b42c2ad7b0f3dab28ac96e2f67ac987dfcbcd7c9bf5f67ca3af586643add6c707da6c5716e7393f0d10f5384f6060200816b8a2242000000
1f8b08003f25bc5d00ff6310e82a70b54f5c2a7223e581e65fd99513e24bc3ce5eabadd5cedfb64b9a79b6c1db98ce9f95e18cf9260d917969ab73a6bacce759fda2e3aa8f8163e581fa2bdf0d1d660100e3496d6a42000000
```

format is `hex(gzip('\x00\x10' || iv || ciphertext ))`

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
