from pwn import *
from binascii import *
from copy import copy
import sys

context.log_level = 'ERROR'

# Have not incuded prefix on this, it's added in the oracle function
c = list(unhexlify('7116bcba27c1abf92602341fd2ea446757f9beae0f0f0bc0de8b9247e5cb6d9847b6055fdd9ebfb08c0909a6fc2ce2eade5dad59c0cefa12040de18fbe7bc7cd88a7d5c973a9201e8eddbf63b718dcb1'))
iv = list(unhexlify('4239390B806A940656AA7033FB95753C'))

def oracle(c):
    r = remote('127.0.0.1', sys.argv[1])
    r.sendline(b"0016"+c)
    l = r.recvline()
    r.close()
    if b'padding' in l: return False
    return True

# Block 2 needs to have padding set for the byte
# Current is index from the end
# last byte is 1
def bruteByte(block1, block2, current):
    block1 = copy(block1)
    initial = block1[-current]
    for i in range(256):
        if current == 1 and initial == i:
            # make sure we are not just returning the initial valid padding
            continue
        block1[-current] = i
        # first block need to go at end to be iv
        if oracle(hexlify(bytes(block2+block1))):
            return i^current^initial
    #if can't find another padding byte for the first then there was only 1 byte of padding
    if current == 1: return 1;
    #print("Byte not found")

def setPadding(block, solved, current):
    block = copy(block)
    for i in range(1, current):
        block[-i] ^= solved[-i]^current
    return block

def solveBlock(block1, block2):
    solved = []
    for current in range(1, len(block2)+1):
        block1Tmp = setPadding(block1, solved, current)
        #print('pad', hexlify(bytes(block1)), hexlify(bytes(block1Tmp)))
        solved = [bruteByte(block1Tmp, block2, current)] + solved
        #print('current:', hexlify(bytes(solved)))
    return solved

def solve():
    blocks = []
    for i in range(0, len(c), 16):
        blocks.append(c[i:i+16])
    p = []
    for i in range(1, len(blocks)):
        p = solveBlock(blocks[-i-1], blocks[-i]) + p
        print('solved block', bytes(p))
        print()
    p = solveBlock(iv, blocks[0]) + p
    print(bytes(p))

solve()
