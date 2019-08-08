# Files
* `common/crypto.nim` Shitty partial high level wrapper around gcrypt + padding
* `common/challenge.nim` logging/exception handling + threading/serving
* `padding.nim` padding oracle challenge

A string for the padding oracle attack is
```
00167116bcba27c1abf92602341fd2ea446757f9beae0f0f0bc0de8b9247e5cb6d9847b6055fdd9ebfb08c0909a6fc2ce2eade5dad59c0cefa12040de18fbe7bc7cd88a7d5c973a9201e8eddbf63b718dcb14239390B806A940656AA7033FB95753C
```

# Dependencies
padding requires `libgcrypt20-dev` and nim for compiling. `libgcrypt20` for running  
solvePadding.py requires python3 and `https://github.com/arthaud/python3-pwntools`

# Running
compile with `nim c --threads:on padding.nim`
run with `./padding <port>`

run solution with `python3 solvePadding.py <port>`

# Docker
```
docker build -t chal .
sudo docker run -it -p 1337:1337 chal
```
