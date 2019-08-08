import threadpool
import net
import nativesockets
import common/challenge
import common/crypto
import os
import strutils

proc paddingChallenge(s: SocketHandle) =
  plsNoDie:
    var sock = newSocket(s, Domain.AF_INET, SOCK_STREAM, IPPROTO_TCP, true)
    sock.send("Enter encrypted authentication: ")
    var auth = sock.recvLine().strip
    if auth.len < 16*4+2 or auth[0..<4] != "0016":
      sock.send("Invalid auth\n")
    else:
      try:
        #TODO change password
        # cur off BS prefix
        var dec = AES_CBC_Dec("YELLOW SUBMARINE", auth[4..auth.high])
        #TODO comparison?
        sock.send("Success\n")
      except ValueError as e:
        sock.send("Invalid auth\n")
      except PaddingError as e:
        sock.send(e.msg&"\n")
    sock.close()

runChallenge(parseInt(paramStr(1)), paddingChallenge)
