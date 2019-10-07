import threadpool
import net
import nativesockets
import common/challenge
import common/crypto
import os
import strutils

proc paddingChallenge(s: SocketHandle) =
  let bs = 16
  plsNoDie:
    let sock = newSocket(s, Domain.AF_INET, SOCK_STREAM, IPPROTO_TCP, true)
    sock.send("Enter encrypted authentication: ")
    let auth = sock.recvLine().strip
    if auth.len < bs*4+2 or auth[0..<4] != "0010":
      sock.send("Invalid auth\n")
    else:
      try:
        # password from head -c 16 /dev/urandom | xxd -ps
        # cut off block size prefix
        let dec = AES_CBC_Dec(parseHexStr("f2dd0183975015e92f60da1202147e09"), auth[4..auth.high])
        # diceware flag
        if dec == "WACTF3{omen-leotard-unjustly-gloomily}":
          sock.send("You are authenticated\n")
        else:
          sock.send("Wrong password\n")
      except ValueError as e:
        sock.send("Invalid auth\n")
      except PaddingError as e:
        sock.send(e.msg&"\n")
    sock.close()

proc main() =
  runChallenge(parseInt(paramStr(1)), paddingChallenge)

main()
