import sys
import serial
from serial.threaded import *
import threading
from Queue import Queue
from time import time
import msvcrt
import colorama
import traceback
import binascii
import struct

colorama.init()


CLR_SCR = "\x1B[2J"
CLR_EOL = "\x1B[0K"
GOTO_BASE = "\x1B[1;1H"
GOTO_INP = "\x1B[20;1H"

sys.stdout.write(CLR_SCR)

command_queue = Queue()

ESC = 0x5A
ESC_EOF = 0
ESC_EOF_NO_CRC = 1
ESC_ESC = 2
ESC_SOF = 0x80
ESC_DBG = 0x40

OOP = False
OOP_ESC = 1
InPacket = 2
InPacketESC = 3
InPacketCRC = 4

class Recv(FramedPacket):


    """
        SM:
          <False> (Out of packet):
             ESC -> OOP_ESC
             other -> drop byte
          OOP_ESC (Start of packet)
             ESC_SOF0 -> InPacket (Pkt type is 1, crc =< 0)
             other -> drop byte, -> OOP
          InPacket (body of pkt)
             ESC -> InPacketESC
             other -> append data (crc += data)
          InPacketESC
             ESC_EOF_NO_CRC -> check crc for ESC, send packet, -> False (OOP)
             ESC_EOF -> InPacketCRC
             ESC_ESC -> data is ESC, append ESC, crc += ESC
             other -> drop byte, -> OOP
          InPacketCRC
             ESC -> drop
             other check crc with data, send packet, -> False (OOP)
    """

    def drop_byte(self, data):
        print "Unexpected byte {} (state is {})".format(data, self.in_packet)
        self.in_packet = OOP
        del self.packet[:]

    def send_pkt(self, expected_crc):
        self.crc &= 0xFF
        if expected_crc != self.crc:
            print "Wrong CRC {} (expected {})".format(expected_crc, self.crc)
        else:
            command_queue.put(('D{}'.format(self.pkt_type), bytes(self.packet), time()))
        self.in_packet = OOP
        del self.packet[:]

    def data_received(self, data):
        for byte in serial.iterbytes(data):
            byte = ord(byte)
            if self.in_packet == OOP:
                if byte == ESC:
                    self.in_packet = OOP_ESC
            elif self.in_packet == OOP_ESC:
                if byte & ESC_SOF:
                    self.in_packet = InPacket
                    self.crc = 0
                    self.pkt_type = byte & ~ESC_SOF
                elif byte == ESC_DBG:
                    self.in_packet = InPacket
                    self.crc = 0
                    self.pkt_type = 'BG'
                else:
                    self.drop_byte(byte)
            elif self.in_packet == InPacket:
                if byte == ESC:
                    self.in_packet = InPacketESC
                else:
                    self.packet.extend(chr(byte))
                    self.crc += byte
            elif self.in_packet == InPacketESC:
                if byte == ESC_EOF_NO_CRC:
                    self.send_pkt(ESC)
                elif byte == ESC_EOF:
                    self.in_packet = InPacketCRC
                elif byte == ESC_ESC:
                    self.packet.extend(chr(ESC))
                    self.crc += ESC
                else:
                    self.drop_byte(byte)    
            elif self.in_packet == InPacketCRC:
                if byte == ESC:
                    self.drop_byte(byte)
                else:
                    self.send_pkt(byte)
            else:
                assert False, "Unexpected state"

class KeyWatcher(threading.Thread):
    def run(self):
        while True:
            sym = msvcrt.getch()
            if sym in ('\0', '\xE0'):
                sym = msvcrt.getch()
            command_queue.put(('K', sym, None))

key_watcher = KeyWatcher()
key_watcher.daemon = True
key_watcher.start()

trace_file = open("trace2.txt", "at")
time_start = time()
last_ts = 0

_help_done = False

S_2_56 = 1
S_1_28 = 2
S_640 = 4
S_320 = 8
S_160 = 16
S_80 = 32
S_40 = 64
S_20 = 128

def voltage(value, scale, mult):
    value = value*2.1*mult/scale/65536
    suf = "V"
    if value < 0.05:
        value *= 1000
        suf = "mV"
    return "{:.2f}{}".format(value, suf)


def V(value, scale, mult=1, shift=0, m2=1):
    img = voltage(value-shift, scale, mult*m2)
    return "{} ({})".format(img, value)

def I(value):
    current = value/14218.0
    suf = "A"
    if current < 0.05:
        current *= 1000
        suf = "mA"
    return "{:.2f}{} ({})".format(current, suf, value)

AF_BL1  = 0x01
AF_BL2  = 0x02
AF_BL3  = 0x04
AF_BL4  = 0x08
AF_CV   = 0x10
AF_ChargeOn = 0x20

def process_data(cmd, data, tm):
    global _help_done, last_ts, last_current
    ts = tm - time_start
    data_hex = binascii.hexlify(data).upper()
    print >>trace_file, "{}:{}:{}".format(ts, cmd, data_hex)
    trace_file.flush()
    sys.stdout.write(GOTO_BASE)
    assert cmd == 'D0'
    FullBat, B1, B2, B3, B4, CurrentSence, Input, ext_adc_flags, V_Adjust = struct.unpack("7H2B", data)

    print "Charge {:3} ({}); Time: {:.1f} (+{:.1f})".format(
        "ON" if (ext_adc_flags & AF_ChargeOn) else "OFF",
        "CV" if (ext_adc_flags & AF_CV) else "CC",
        ts, ts-last_ts
    ) + CLR_EOL
    last_ts = ts
    print "V Inp: {:15};  V Out: {:15}; Charge: {:15}; Voltage Adjust: {:4}".format(
        V(Input,   S_2_56, 10),
        V(FullBat, S_2_56, 10, m2=1.01),
        I(CurrentSence),
        V_Adjust,
    ) + CLR_EOL
    print CLR_EOL
    print "               1                2                3                4"
    print "Battery - {:15}  {:15}  {:15}  {:15}".format(
        V(B1, S_640, 10, m2=1.01),
        V(B2, S_640, 10, m2=1.01),
        V(B3, S_640, 10, m2=1.01),
        V(B4, S_640, 10, m2=1.01),
    ) + CLR_EOL
    print "Balance - {:15}  {:15}  {:15}  {:15}".format(
        "ON" if (ext_adc_flags & AF_BL1) else "OFF",
        "ON" if (ext_adc_flags & AF_BL2) else "OFF",
        "ON" if (ext_adc_flags & AF_BL3) else "OFF",
        "ON" if (ext_adc_flags & AF_BL4) else "OFF"
    ) + CLR_EOL
    print CLR_EOL
    print "Raw:", data_hex + CLR_EOL

    if not _help_done:
        print "\n\n\n"
        print "Q - Quit"
        _help_done = True

def process_keypress(sym):
    global key_watcher
    sym = sym.lower()
    if sym == 'q':
        sys.exit(0)

print >>trace_file, "{}:!".format(time_start)

with ReaderThread(serial.Serial("COM8", baudrate=115200), Recv) as protocol:
    while True:
        cmd, data, aux = command_queue.get()
        if cmd == "DBG":
            d, = struct.unpack("H", data)
            print "{0} (0x{0:X})".format(d) + CLR_EOL
        elif cmd[0] == 'D':
            process_data(cmd, data, aux)
        elif cmd == 'K':
            process_keypress(data)
