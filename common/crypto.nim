import gcrypt
import strutils

type CryptoError* = object of Exception
type PaddingError* = object of Exception

# not defined in the bindings for some reason
template gcry_cipher_final(cipher: untyped): untyped =
  gcry_cipher_ctl(cipher, (cint) GCRYCTL_FINALIZE, nil, 0)

template check_rc(rc: gcry_error_t): untyped =
  ## Expect return code to be 0, raise an exception otherwise
  {.line: instantiationInfo().}:
    if rc != 0.cint:
      raise newException(CryptoError, $gcry_strerror(rc))

proc init*() =
  if gcry_check_version(GCRYPT_VERSION) != GCRYPT_VERSION:
    raise newException(CryptoError, "Gcrypt version mismatch")
  # Don't bother with secure memory
  check_rc(gcry_control(GCRYCTL_DISABLE_SECMEM, 0))
  check_rc(gcry_control(GCRYCTL_INITIALIZATION_FINISHED, 0))

proc pkcs7Pad*(p: string): string =
  var pad = 16 - (p.len mod 16)
  return p & repeat((char) pad, pad)

proc pkcs7Unpad*(p: string): string =
  var pad = (int) p[p.high]
  if pad <= 0 or pad > 16:
    raise newException(PaddingError, "Invalid PKCS#7 padding")
  for padTest in p[p.len-pad..p.high]:
    if padTest != (char) pad:
      raise newException(PaddingError, "Invalid PKCS#7 padding")
  return p[0..p.high-pad]

proc AES_CBC_Enc*(k, p: string): string =
  var
    p = pkcs7Pad(p)
    cipher: gcry_cipher_hd_t = nil
    iv = newString(16)
    c = newString(p.len) # length should be the same since p is padded
  gcry_randomize((cstring) iv, 16, GCRY_STRONG_RANDOM)
  # bindings don't handle the enum types properly :(
  check_rc(gcry_cipher_open(addr cipher, (cint) GCRY_CIPHER_AES256, (cint) GCRY_CIPHER_MODE_CBC, 0))
  defer: gcry_cipher_close(cipher)
  check_rc(gcry_cipher_setkey(cipher, (cstring) k, k.len))
  check_rc(gcry_cipher_setiv(cipher, (cstring) iv, iv.len))
  check_rc(gcry_cipher_final(cipher))
  check_rc(gcry_cipher_encrypt(cipher, (cstring) c, c.len, (cstring) p, p.len))
  return toHex(c&iv)

proc AES_CBC_Dec*(k, c: string): string =
  var c = parseHexStr(c)
  var
    cipher: gcry_cipher_hd_t = nil
    iv = c[c.len-16..<c.len]
    p = newString(c.len - 16) # minus iv
  c = c[0..<c.len-16]
  # bindings don't handle the enum types properly :(
  check_rc(gcry_cipher_open(addr cipher, (cint) GCRY_CIPHER_AES256, (cint) GCRY_CIPHER_MODE_CBC, 0))
  defer: gcry_cipher_close(cipher)
  check_rc(gcry_cipher_setkey(cipher, (cstring) k, k.len))
  check_rc(gcry_cipher_setiv(cipher, (cstring) iv, iv.len))
  check_rc(gcry_cipher_final(cipher))
  check_rc(gcry_cipher_decrypt(cipher, (cstring) p, p.len, (cstring) c, c.len))
  return pkcs7unpad(p)
