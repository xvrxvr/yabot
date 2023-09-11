import sys
import serial
from serial.threaded import *
import threading
from Queue import Queue
from time import time
import msvcrt
import colorama
import numpy as np
import traceback

colorama.init()


CLR_SCR = "\x1B[2J"
CLR_EOL = "\x1B[0K"
GOTO_BASE = "\x1B[1;1H"
GOTO_INP = "\x1B[20;1H"

sys.stdout.write(CLR_SCR)

command_queue = Queue()

class Recv(LineReader):
    def handle_line(self, data):
        command_queue.put(('D', data, time()))

class KeyWatcher(threading.Thread):
    def run(self):
        while True:
            sym = msvcrt.getch()
            if sym in ('\0', '\xE0'):
                sym = msvcrt.getch()
            command_queue.put(('K', sym, None))
            if sym in 'iI':
                break

key_watcher = KeyWatcher()
key_watcher.daemon = True
key_watcher.start()

trace_file = open("trace.txt", "at")
time_start = time()
last_ts = 0
last_current = None
current_x = []  # Sample of CurrentSence
current_y = []  # Real Current (in Amp)
curent_poly = None

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
    #if not curent_poly:
    #    return str(value)
    #try:
    current = value/14218.0
    #except Exception as e:
    #    return "{} - ??? Exception {}".format(str, e)
    suf = "A"
    if current < 0.05:
        current *= 1000
        suf = "mA"
    return "{:.2f}{} ({})".format(current, suf, value)

def process_data(data, tm):
    global _help_done, last_ts, last_current
    ts = tm - time_start
    print >>trace_file, "{}:D:{}".format(ts, data)
    trace_file.flush()
    sys.stdout.write(GOTO_BASE)
    data_vec = data.split(',')
    mode = data_vec.pop()
    Zero, FullBat, B1, B2, B3, B4, CurrentSence, Input, BL1, BL2, BL3, BL4, CC_CV, Charge, V_Adjust = [int(x) for x in data_vec]

    last_current = CurrentSence
    print "Zero: {:15}  CC/CV: {:15}             Time: {:.1f} (+{:.1f})".format(
        V(Zero, S_20, 1, 0x8000),
        V(CC_CV, S_2_56, 10, 0x8000),
        ts, ts-last_ts
    ) + CLR_EOL
    last_ts = ts
    print CLR_EOL
    print "               1                2                3                4"
    print "Battery - {:15}  {:15}  {:15}  {:15}".format(
        V(B1, S_640, 10, m2=1.01),
        V(B2, S_640, 10, m2=1.01),
        V(B3, S_640, 10, m2=1.01),
        V(B4, S_640, 10, m2=1.01),
    ) + CLR_EOL
    print "Balance - {:15}  {:15}  {:15}  {:15}".format(
        V(BL1, S_640, 10),
        V(BL2, S_640, 10),
        V(BL3, S_640, 10),
        V(BL4, S_640, 10),
    ) + CLR_EOL
    print CLR_EOL
    print "V Inp: {:15}     V Out: {:15}            Charge: {}".format(
        V(Input,   S_2_56, 10),
        V(FullBat, S_2_56, 10, m2=1.01),
        I(CurrentSence)
    ) + CLR_EOL
    print "Voltage Adjust: {:4}       Charge path: {:17}    Charge is {}".format(
        V_Adjust,
        V(Charge, S_2_56, 1, 0x8000),
        "ON" if mode == "+" else "OFF"
    ) + CLR_EOL
    print CLR_EOL
    print "Raw:", data + CLR_EOL

    if not _help_done:
        print "\n\n\n"
        print """Q - Quit
I - Charge current"""
        _help_done = True

def process_keypress(sym):
    global key_watcher
    sym = sym.lower()
    if sym == 'q':
        sys.exit(0)

    if sym == 'i':
        ts = time() - time_start
        val = raw_input(GOTO_INP + "Charge current > ")
        try:
            val = float(val)
        except:
            print "Not a FP value!"
            key_watcher = KeyWatcher()
            key_watcher.daemon = True
            key_watcher.start()
            return
        print >>trace_file, "{}:I:{}".format(ts, val)
        print GOTO_INP + CLR_EOL
        key_watcher = KeyWatcher()
        key_watcher.daemon = True
        key_watcher.start()
        new_current(last_current, val)
        return


def new_current(measured, real):
    current_x.append(measured)
    current_y.append(real)
    if len(current_x) >= 2:
        print GOTO_INP
        try:
            x = np.array(current_x)
            y = np.array(current_y)
            z = np.polyfit(x, y, 1)
            curent_poly = np.poly1d(z, variable="X")
        except Exception:
            curent_poly = None
            traceback.print_exc()


print >>trace_file, "{}:!".format(time_start)

with ReaderThread(serial.Serial("COM8", baudrate=115200), Recv) as protocol:
    while True:
        cmd, data, aux = command_queue.get()
        if cmd == 'D':
            process_data(data, aux)
        elif cmd == 'K':
            process_keypress(data)




