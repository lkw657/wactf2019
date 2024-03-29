import threadpool
import net
import nativesockets
import logging
import crypto as crypto
import strformat

# Not wrapping c++ anymore
#[
type
  std_exception* {.importcpp: "std::exception", header: "<exception>".} = object

proc what*(s: std_exception): cstring {.importcpp: "((char *)#.what())".}
]#

proc makeErrorMsg(e: ref Exception): string =
  result = &"\x1b[1;31mYOU DUN FUCKED UP\n{$e.name}: {e.msg}\n{getStackTrace(e)}\x1b[0m"

template plsNoDie*(stmts: untyped) =
  let logger = newConsoleLogger(fmtStr="\x1b[1;31m$levelname [$datetime] -- $appname: \x1b[0m", useStderr=true)
  #addHandler(logger)
  try:
    stmts
  except Exception as e:
    #error(makeErrorMsg(e))
    logger.log(lvlError, makeErrorMsg(e))

template runChallenge*(port: int, run: proc(s:SocketHandle){.nimcall.}) =
  crypto.init()
  let socket = newSocket()
  var client: Socket
  socket.bindAddr(Port(port))
  socket.listen()   
  echo "Waiting for connections"
  while true:    
    socket.accept(client)
    # can't use a GC'd reference because memory safety
    spawn run(getFd(client))
  socket.close()
  sync()

