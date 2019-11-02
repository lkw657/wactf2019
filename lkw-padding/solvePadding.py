#!/usr/bin/env python3
from binascii import *
from copy import copy
import sys
import socket
import gzip

CHUNK_SIZE = 128
BS=16

combined = gzip.decompress(unhexlify('1f8b08003f25bc5d00ff6310e82a70b54f5c2a7223e581e65fd99513e24bc3ce5eabadd5cedfb64b9a79b6c1db98ce9f95e18cf9260d917969ab73a6bacce759fda2e3aa8f8163e581fa2bdf0d1d660100e3496d6a42000000'))
combined = combined[2:] # cut off the block size prefix
#iv = combined[:BS]
#c = combined[BS:]
#print('c:', hexlify(c))
#print('iv:', hexlify(iv))
#c=list(c)
#iv=list(iv)
combined = list(combined)

def oracle(c):
    '''
    Padding oracle function
    Returns true if the ciphertext was decrypted successfully, false if there was a padding error
    '''
    with socket.create_connection(('127.0.0.1', sys.argv[1])) as sock:
        #print('want', hexlify(b"\x00\x10"+c))
        payload = hexlify(gzip.compress(b"\x00\x10"+c)) + b'\n'
        #print('sending', payload)
        sock.send(payload)
        # read a line
        # fuck python's low level sockets
        buffer = bytearray()
        while True:
          chunk = sock.recv(CHUNK_SIZE)
          #print("got", chunk)
          buffer.extend(chunk)
          if b'\n' in chunk or not chunk:
            break
        #l = buffer[:buffer.find(b'\n')]
        #if b'padding' in l: return False
        #return True
        return not (b'padding' in buffer)

# Block 2 needs to have padding set for the byte
# Current is index from the end of byte that's being bruteforced
# last byte is 1
def bruteByte(block1, block2, current):
    block1 = copy(block1)
    # original value of this byte
    initial = block1[-current]
    # brute force the byte
    for i in range(256):
        if current == 1 and initial == i:
            # make sure we are not just returning the initial valid padding
            continue
        block1[-current] = i
        if oracle(bytes(block1+block2)):
            return i^current^initial
    #if can't find another padding byte for the first then there was only 1 byte of padding
    if current == 1: return 1;
    #print("Byte not found")

# use the currently known plaintext to set the padding of the block to current
def setPadding(block, solved, current):
    block = copy(block)
    for i in range(1, current):
        block[-i] ^= solved[-i]^current
    return block

def solveBlock(block1, block2):
    solved = []
    # bruteforce every byte in the block
    for current in range(1, len(block2)+1):
        block1Tmp = setPadding(block1, solved, current)
        #print('pad', hexlify(bytes(block1)), hexlify(bytes(block1Tmp)))
        solved = [bruteByte(block1Tmp, block2, current)] + solved
        #print('current:', hexlify(bytes(solved)))
    return solved

def solve():
    # ciphertext blocks
    blocks = []
    for i in range(0, len(combined), BS):
        blocks.append(combined[i:i+BS])
    # plaintext
    p = []
    # solve every block
    for i in range(1, len(blocks)):
        #p = solveBlock(blocks[-i-1], blocks[-i]) + p
        p += solveBlock(blocks[i-1], blocks[i])
        print('solved block', bytes(p))
        print()
    #p = solveBlock(iv, blocks[0]) + p
    # print result
    print(bytes(p))

print("Solving")
solve()
