from binascii import *
from copy import copy
import sys
import socket

CHUNK_SIZE = 128

BS=16

# Have not incuded prefix on this, it's added in the oracle function
c = list(unhexlify('0b259178b56a276768b136dcd88eaa40856de4111b281b1aa5a89f8c7527b05d15951b3950d5dd59e8c9742ff7abc051'))
iv = list(unhexlify('4ac8b870ebead9a979c5d33e7b8bf3cf'))

def oracle(c):
    with socket.create_connection(('127.0.0.1', sys.argv[1])) as sock:
        sock.send(b"0010"+c+b'\n')
        # read a line
        # fuck python's low level sockets
        buffer = bytearray()
        while True:
          chunk = sock.recv(CHUNK_SIZE)
          buffer.extend(chunk)
          if b'\n' in chunk or not chunk:
            break
        l = buffer[:buffer.find(b'\n')]
        if b'padding' in l: return False
        return True

# Block 2 needs to have padding set for the byte
# Current is index from the end
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
        if oracle(hexlify(bytes(block2+block1))):
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

solve()
