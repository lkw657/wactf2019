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
  #if gcry_check_version(GCRYPT_VERSION) != GCRYPT_VERSION:
  #  raise newException(CryptoError, "Gcrypt version mismatch")
  # Don't bother with secure memory
  check_rc(gcry_control(GCRYCTL_DISABLE_SECMEM, 0))
  check_rc(gcry_control(GCRYCTL_INITIALIZATION_FINISHED, 0))

proc pkcs7Pad*(p: string, padSiz: int): string =
  var pad = padSiz - (p.len mod padSiz)
  return p & repeat((char) pad, pad)

proc pkcs7Unpad*(p: string, padSiz: int): string =
  let pad = (int) p[p.high]
  if pad <= 0 or pad > padSiz:
    raise newException(PaddingError, "Invalid PKCS#7 padding")
  for padTest in p[p.len-pad..p.high]:
    if padTest != (char) pad:
      raise newException(PaddingError, "Invalid PKCS#7 padding")
  return p[0..p.high-pad]

proc CipherCBCEnc*(k, p: string, bs: int, cipherAlgo: gcry_cipher_algos): string =
  let p = pkcs7Pad(p, bs)
  var
    cipher: gcry_cipher_hd_t = nil
    iv = newString(bs)
    c = newString(p.len) # length should be the same since p is padded
  gcry_randomize((cstring) iv, (uint) bs, GCRY_STRONG_RANDOM)
  # bindings don't handle the enum types properly :(
  check_rc(gcry_cipher_open(addr cipher, (cint) cipherAlgo, (cint) GCRY_CIPHER_MODE_CBC, 0))
  defer: gcry_cipher_close(cipher)
  check_rc(gcry_cipher_setkey(cipher, (cstring) k, (uint) k.len))
  check_rc(gcry_cipher_setiv(cipher, (cstring) iv, (uint) iv.len))
  check_rc(gcry_cipher_final(cipher))
  check_rc(gcry_cipher_encrypt(cipher, (cstring) c, (uint) c.len, (cstring) p, (uint) p.len))
  return toHex(c&iv)


proc DES_CBC_Enc*(k, p: string): string =
  return CipherCBCEnc(k, p, 8, GCRY_CIPHER_DES)

proc AES_CBC_Enc*(k, p: string): string =
  return CipherCBCEnc(k, p, 16, GCRY_CIPHER_AES256)

proc CipherCBCDec*(k, c: string, bs: int, cipherAlgo: gcry_cipher_algos): string =
  var
    cipher: gcry_cipher_hd_t = nil
    iv = c[c.len-bs..<c.len]
    p = newString(c.len - bs) # minus iv
  var c = c[0..<c.len-bs]
  # bindings don't handle the enum types properly :(
  check_rc(gcry_cipher_open(addr cipher, (cint) cipherAlgo, (cint) GCRY_CIPHER_MODE_CBC, 0))
  defer: gcry_cipher_close(cipher)
  check_rc(gcry_cipher_setkey(cipher, (cstring) k, (uint) k.len))
  check_rc(gcry_cipher_setiv(cipher, (cstring) iv, (uint) iv.len))
  check_rc(gcry_cipher_final(cipher))
  check_rc(gcry_cipher_decrypt(cipher, (cstring) p, (uint) p.len, (cstring) c, (uint) c.len))
  return pkcs7unpad(p, bs)

proc AES_CBC_Dec*(k, c: string): string =
  CipherCBCDec(k, c, 16, GCRY_CIPHER_AES256)

proc DES_CBC_Dec*(k, c: string): string =
  CipherCBCDec(k, c, 8, GCRY_CIPHER_DES)
