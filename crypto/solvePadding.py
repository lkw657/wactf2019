#!/usr/bin/env python3
from binascii import *
from copy import copy
import sys
import socket
import gzip

CHUNK_SIZE = 128

BS=16

combined = gzip.decompress(unhexlify('1f8b0800b71f9b5d00ff6310e0569d58b1354b3d3d63a3d99d1b7dab1c5a739f084a6b484b2d5d31bfa7547d43ace85469cb80ab77235f9c2cd1ffbefa40a0d7891d05af5fdd5c5979f4b25d75f7e7f3001a9ee0c142000000'))
c = combined[:len(combined)-BS][2:]
iv = combined[len(combined)-BS:]
print('c:', hexlify(c))
print('iv:', hexlify(iv))
c=list(c)
iv=list(iv)

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
        # first block needs to go at end to be iv
        #print("block2", block2, "\n", 'block1', block1)
        if oracle(bytes(block2+block1)):
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
    for i in range(0, len(c), BS):
        blocks.append(c[i:i+BS])
    # plaintext
    p = []
    # solve every block
    for i in range(1, len(blocks)):
        p = solveBlock(blocks[-i-1], blocks[-i]) + p
        print('solved block', bytes(p))
        print()
    p = solveBlock(iv, blocks[0]) + p
    # print result
    print(bytes(p))

print("Solving")
solve()
