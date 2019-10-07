import threadpool
import net
import nativesockets
import common/challenge
import common/crypto
import os
import strutils
import common/zlib

proc paddingChallenge(s: SocketHandle) =
  let bs = 16
  plsNoDie:
    let sock = newSocket(s, Domain.AF_INET, SOCK_STREAM, IPPROTO_TCP, true)
    defer: sock.close()
    sock.send("Enter encrypted authentication: ")
    try:
      let auth = uncompress(parseHexStr(sock.recvLine().strip))
      # at least 2 blocks + blocksize header and multiple of block size (minus header)
      if auth.len < 2*bs+2 or ((auth.len - 2) mod bs != 0):
        sock.send("Invalid auth\n")
        return
      if auth[0..<2] != "\x00\x10":
        sock.send("Invalid auth\n")
        return
      # cut off block size prefix
      let combined = auth[2..auth.high]
      # password from head -c 16 /dev/urandom | xxd -ps
      let dec = AES_CBC_Dec(parseHexStr("f2dd0183975015e92f60da1202147e09"), combined)
      # diceware flag
      if dec == "WACTF3{omen-leotard-unjustly-gloomily}":
        sock.send("You are authenticated\n")
      else:
        sock.send("Wrong password\n")
    except ZlibStreamError:
      # player did not send a valid gzip
      sock.send("Invalid auth\n")
    except ValueError as e:
      # not a valid hex string
      sock.send("Invalid auth\n")
    except PaddingError as e:
      sock.send(e.msg&"\n")

proc main() =
  runChallenge(parseInt(paramStr(1)), paddingChallenge)

main()
