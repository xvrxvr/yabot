from collections import namedtuple
from copy import deepcopy
import re
import png
import VGA8X16 as font

Box = namedtuple('Box', ('x1', 'y1', 'x2', 'y2'))

W = 320
H = 240

CMD_END = 0
CMD_TEXT = 1
CMD_BOX = 0x20
CMD_RECT = 0x21

h_file = open("scr_script.h", "wt")
print >>h_file, "#pragma once"
print >>h_file, "#define MSG_TOP_Y", (H-16)

c_file = open("scr_script.c", "wt")
print >>c_file, '#include "common.h"'
print >>c_file, '#include "scr_script.h"'


class PngPicture(object):
    counter = 0
    last_scripts = {}
    colors_toc = {}
    colors_toc2 = {}
    colors_data = []

    def __init__(self, name, title=None, footer=None):
        self.script = []
        self.screen = [966 * [255]]
        for row in range(240):
            self.screen.append([255, 255, 255] + (960 * [0]) + [255, 255, 255])
        self.screen.append(966 * [255])
        self.name = name
        self.overlay_name = ''
        self.title = title or name.upper()
        self.rgb_bg = C_BG
        self.rgb_text = C_BODY_TEXT

        print >>c_file, "//  ----- {} -------".format(name)

        ttl = 16
        if title is not False:
            with self.text_def(C_TITLE_TEXT, C_TITLE_BG):
                self.text('fill', 0, self.title)
        else:
            ttl = 0

        if footer:
            self.box(0,ttl,W,H-16-ttl, C_BG)
            self.footer(footer)
        else:
            self.box(0,ttl,W,H-ttl, C_BG)


    def write(self):
        fname = "pix{:02d}.png".format(self.counter)
        PngPicture.counter += 1
        with open(fname, 'wb') as f:
            w = png.Writer(322, 242, greyscale=False)
            w.write(f, self.screen)
        

    class Overlay(object):
        def __init__(self, pic, name):
            self.pic = pic
            self.name = name
            print >>c_file, "//  Overlay - {} -".format(name)

        def __enter__(self):
            self.org_screen = deepcopy(self.pic.screen)
            self.pic.save_script()
            self.pic.script = []
            return self

        def __exit__(self, p1, p2, p3):
            if not p1:
                self.pic.save_script(self.name)
                self.pic.write()
            self.pic.screen = self.org_screen
            self.pic.overlay_name = ''

    def overlay(self, name):
        self.save_script()
        self.overlay_name = name
        return self.Overlay(self, name)

    def __enter__(self):
        return self

    def __exit__(self, p1, p2, p3):
        if not p1:
            self.save_script()
            self.write()

    def save_script(self, name_suffix=''):
        if self.script:
            msg = "screen_" + self.name
            if name_suffix:
                msg += "_"+name_suffix
            script_body = ','.join("0x{:02X}".format(v) for v in self.script)
            if script_body in self.last_scripts:
                print >>h_file, "#define " + msg + " " + self.last_scripts[script_body]
                print >>c_file, "// `" + msg + "` is alias of `" + self.last_scripts[script_body] + "`"
            else:
                print >>h_file, "extern __code uint8_t " + msg + "[];"
                print >>c_file, "__code uint8_t " + msg + "[] = {" + ','.join("0x{:02X}".format(v) for v in self.script) + ",0};"
                PngPicture.last_scripts[script_body] = msg
        self.script = False    

    @classmethod
    def map_color(cls, color, force=False):
        if color in cls.colors_toc:
            if not force:
                return cls.colors_toc[color]
            result = len(cls.colors_data)
        else:
            cls.colors_toc[color] = result = len(cls.colors_data)
        if cls.colors_data:
            cc = cls.colors_data[-1] + color
            if cc not in cls.colors_toc2:
                cls.colors_toc2[cc] = len(cls.colors_data)-1
        cls.colors_data.append(color)
        return result

    @classmethod
    def map_color_pair(cls, c1, c2):
        cc = c1+c2
        if cc in cls.colors_toc2:
            return cls.colors_toc2[cc]
        if cls.colors_data:
            if cls.colors_data[-1] == c1:
                cls.map_color(c2, True)
                return cls.colors_toc2[cc]
        cls.map_color(c1, True)
        cls.map_color(c2, True)
        return cls.colors_toc2[cc]

    @classmethod
    def gen_color(cls, name, color):
        print >>h_file, "#define COLOR_{} {}".format(name.upper(), 2*cls.map_color(color))

    @classmethod
    def gen_color_pair(cls, name, c1, c2):
        print >>h_file, "#define COLOR2_{} {}".format(name.upper(), 2*cls.map_color_pair(c1, c2))

    @classmethod
    def save_pallete(cls):
        acc = []
        for r, g, b in cls.colors_data:
            b1 = (r<<3) | (g>>2)
            b2 = ((g<<6) & 0xC0) | b;
            if b2 & 0x40:
                b2 |= 0x20
            acc.append("0x{:02X}".format(b1))
            acc.append("0x{:02X}".format(b2))
        print >>c_file, "__code uint8_t colors_map[] = {" + ",".join(acc) + "};"

    def add2script_opc(self, opc, ovr_x=0, ovr_dx=0, bit8=False, bit7=False):
        assert self.script is not False
        if ovr_x >= 256 or bit8:
            opc |= 0x80
        if ovr_dx >= 256 or bit7:
            opc |= 0x40
        self.script.append(opc)

    def add2script_opc20(self, x, y, dx, dy, color, opc):
        self.add2script_opc(opc, x, dx)
        self.script.extend([x&0xFF, y, self.map_color(color)*2, dx&0xFF, dy])

    def add2script_text(self, x, y, text, color_text, color_bg, mult):
        self.add2script_opc(CMD_TEXT, x, bit7=(mult==2))
        self.script.extend([x&0xFF, y, self.map_color_pair(color_text, color_bg)*2])
        for s in text:
            self.script.append(ord(s))
        self.script.append(0)


    def put(self, x, y, rgb):
        x += 1
        x *= 3
        row = self.screen[y+1]
        def rr(v):
            result = v << 3
            if v&1:
                result |= 7
            return result
        row[x]   = rr(rgb[0])
        row[x+1] = rr(rgb[1])
        row[x+2] = rr(rgb[2])

    def _box(self, x, y, dx, dy, rgb):
        for xx in range(dx):
            for yy in range(dy):
                self.put(x+xx, y+yy, rgb)

    def box(self, x, y, dx, dy, rgb):
        self._box(x, y, dx, dy, rgb)
        print >>c_file, "// Box: x={}, y={}, dx={}, dy={}, rgb={}".format(x, y, dx, dy, rgb)
        self.add2script_opc20(x, y, dx, dy, rgb, CMD_BOX)

    def _rect(self, x, y, dx, dy, rgb):
        for xx in range(dx):
            self.put(x+xx, y, rgb)
            self.put(x+xx, y+dy-1, rgb)
        for yy in range(dy):
            self.put(x, y+yy, rgb)
            self.put(x+dx-1, y+yy, rgb)

    def pbar(self, x, y, dx, dy, rgb_pb, rgb_outline):
        o_x = x-2
        o_y = y-2
        o_dx = dx+4
        o_dy = dy+4
        self._rect(o_x, o_y, o_dx, o_dy, rgb_outline)
        print >>c_file, "// PBar: x={}, y={}, dx={}, dy={}, rgb={}, rgb_outline={}".format(x, y, dx, dy, rgb_pb, rgb_outline)
        self.add2script_opc20(o_x, o_y, o_dx, o_dy, rgb_outline, CMD_RECT)
        sec_name = self.name
        if self.overlay_name:
            sec_name += "_" + self.overlay_name
        print >>h_file, "#define PB_{name} {x}, {y}, {dx}, {dy}, {rgb}".format(
            name=sec_name.upper(), x=x, y=y, dx=dx, dy=dy, rgb=self.map_color(rgb_pb)*2)

    class TD(object):
        def __init__(self, own):
            self.own = own
            self.rgb_text = own.rgb_text
            self.rgb_bg = own.rgb_bg

        def __enter__(self):
            pass

        def __exit__(self, p1, p2, p3):
            if not p1:
                self.own.rgb_text = self.rgb_text
                self.own.rgb_bg = self.rgb_bg

    def text_def(self, rgb_text=None, rgb_bg=None):
        result = self.TD(self)
        if rgb_text:
            self.rgb_text = rgb_text 
        if rgb_bg:
            self.rgb_bg = rgb_bg
        return result

    def _clr_text(self, text):
        pure_str = ""
        blank_str = ""
        shifts = {}
        for w in re.findall(r'\[.*?\]|[^[]+', text):
            if w[0] != '[':
                pure_str += w
                blank_str += w
            else:
                name, _, word = w[1:-1].partition('$')
                shifts[name] = len(pure_str)
                pure_str += word
                blank_str += len(word) * " "

        return pure_str, blank_str, shifts

    GAP = 5  # Gap between screen and text start/end
    def text(self, x, y, text, mult=1):
        # x:
        #  -1 - center
        #  header - place in header (y - align)
        #  footer - place in footer (y - align)
        #  fill - wrap centered in filled box (y-real coordinate)
        #   if text starts with '<' - left align
        # y:
        #  '>' - rigth align
        if text[0] in '<>':
            sgn = text[0]
            text = text[1:]
        else:
            sgn='<>'
        text, blank_text, shifts = self._clr_text(text)
        align = ''
        do_fill = (x == 'fill')
        if x == -1:
            align = '<>'
        elif x in ('header', 'footer'):
            align = y
        elif do_fill:
            align  = sgn
        if x == 'header':
            y = 0
            color = (C_TITLE_TEXT, C_TITLE_BG)
        elif x == 'footer':
            y = H-16
            color = (C_STATUS_TEXT, C_STATUS_BG)
        else:
            color = (None, None)


        pixels_width = len(text)*8*mult

        if align == '<':
            x = self.GAP
        elif align == '>':
            x = W - pixels_width-self.GAP
        elif align == '<>':
            x = (W - pixels_width) >> 1

        with self.text_def(*color):
            if do_fill:
                if x:
                    self.box(0, y, x, 16*mult, self.rgb_bg)
                if x+pixels_width < W:
                    self.box(x+pixels_width, y, W-(x+pixels_width), 16*mult, self.rgb_bg)

            print  >>c_file, "// Text: '{}', x={}, y={}, mult={}, fg={}, bg={}".format(text, x, y, mult, self.rgb_text, self.rgb_bg)
            self.add2script_text(x, y, blank_text, self.rgb_text, self.rgb_bg, mult)
            sec_name = self.name
            if self.overlay_name:
                sec_name += "_" + self.overlay_name
            for sh, delta in shifts.items():
                print >>h_file, "#define SEC_{name}_{sh} {x}, {y}, {cp}".format(
                    name=sec_name.upper(), sh=sh.upper(), x=x+delta*8*mult, y=y, cp=2*self.map_color_pair(self.rgb_text, self.rgb_bg))
                print >>h_file, "#define SEC_{name}_{sh}_NC {x}, {y}".format(name=sec_name.upper(), sh=sh.upper(), x=x+delta*8*mult, y=y)

            org_x = x
            for ch in text:
                pos = font.height * ord(ch)
                for yy in range(font.height):
                    bits = font.sg[pos]
                    pos += 1
                    for xx in range(8):
                        self._box(x+xx*mult, y+yy*mult, mult, mult, self.rgb_text if bits&0x80 else self.rgb_bg)
                        bits <<= 1
                x += 8*mult
        return Box(org_x, y, x, y+font.height*mult)

    def footer(self, text):
        with self.text_def(C_STATUS_TEXT, C_STATUS_BG):
            self.text('fill', H-16, text)


C_RED = (31, 0, 0)
C_GREEN = (0, 31, 0)
C_BLUE = (0, 0, 31)
C_WHITE = (31, 31, 31)
C_BLACK = (0,0,0)

C_GRAY = (15,15,15)
C_DGRAY = (8,8,8)
C_DBLUE = (0, 0, 15)

######## colors
C_BG = C_BLACK

# Top line
C_TITLE_BG = C_DGRAY
C_TITLE_TEXT = C_WHITE

# Bottom line
C_STATUS_BG = C_GRAY
C_STATUS_TEXT = C_BLACK

# Body
C_BODY_TEXT = C_WHITE
C_BODY_TEXT_HL = C_RED

# Progress bar
C_PROGRESS_BODY = C_GREEN
C_PROGRESS_BRD = C_GRAY

PngPicture.gen_color("black", C_BLACK)

PngPicture.gen_color_pair("bg", C_BODY_TEXT, C_BG)
# Bat cells colors
PngPicture.gen_color_pair("bat_udf", C_BLACK, C_RED)
PngPicture.gen_color_pair("bat_ovf", C_RED, C_BLACK)
PngPicture.gen_color_pair("bat_bal", C_GREEN, C_BLACK)
# VAdj pair
PngPicture.gen_color("vadj_color_1", C_BLUE)
PngPicture.gen_color("vadj_color_2", C_RED)

with PngPicture(name="wait", title=False) as p:
    p.text(-1, 100, "Please, wait ...", 2)

with PngPicture(name="nobat", title="OFFLINE") as p:
    b = p.text(-1, 40, "No Battery", 2)
    p.text(-1, b.y2+10, "Connected", 2)

with PngPicture(name="offline") as p:

    b = p.text(-1, 30, "Battery: [bat$14.8]V", 2)
    b = p.text(-1, b.y2+5, "C1: [c1$4.21]V", 2)
    b = p.text(-1, b.y2+1, "C2: [c2$4.01]V", 2)
    b = p.text(-1, b.y2+1, "C3: [c3$4.01]V", 2)
    b = p.text(-1, b.y2+1, "C4: [c4$4.01]V", 2)

    with p.overlay(name='last_ch_msg'):
        p.footer("Last Charging time: [time$1:10]")
    with p.overlay(name='abort'):
        p.footer("<Charging Aborted: [msg$why]")
    with p.overlay(name='dead'):
        p.footer("Dead battery (replace cells)")
    with p.overlay(name='overcharge'):
        p.footer("Overcharged battery")

with PngPicture(name="online") as p:

    b = p.text(-1, 17,     "  Input: [inp$14.8]V", 2)
    b = p.text(-1, b.y2+1, "Battery: [bat$14.8]V", 2)
    b = p.text(-1, b.y2+5, "C1: [c1$4.21]V", 2)
    b = p.text(-1, b.y2+1, "C2: [c2$4.01]V", 2)
    b = p.text(-1, b.y2+1, "C3: [c3$4.01]V", 2)
    b = p.text(-1, b.y2+1, "C4: [c4$4.01]V", 2)

    with p.overlay(name='start'):
        p.footer("Press knob to start charging")
    with p.overlay(name='last_ch_msg'):
        p.footer("Last Charging time: [time$1:10]")
    with p.overlay(name='abort'):
        p.footer("<Charging Aborted: [msg$why]")
    with p.overlay(name='dead'):
        p.footer("Dead battery (replace cells)")
    with p.overlay(name='overcharge'):
        p.footer("Overcharged battery")

SP = 7
BW = 3
SS = 3

with PngPicture(name="charge", title="CHARGE", footer="<Charge time: [elapsed$1:10:00]") as p:

    b = p.text(-1, 20, "Input: [inp$14.8]V", 2)
    b = p.text(-1, b.y2+15, "Charge: [ch_v$14.8]V/[ch_i$1.15]A", 2)

    b1 = p.text(8, b.y2+10, "C1: [c1$4.08]V", 2)
    p.box(b1.x2 + SP, b1.y1, BW, 32*2+SS, C_BODY_TEXT)
    b = p.text(b1.x2+2*SP+BW, b1.y1, "C2: [c2$4.08]V", 2)

    b1 = p.text(8, b.y2+SS, "C3: [c3$4.08]V", 2)
    b = p.text(b1.x2+2*SP+BW, b1.y1, "C4: [c4$4.08]V", 2)

    # Progress bar
    PBX = 10
    PBH = 28
    p.pbar(PBX, b.y2+10, W-PBX*2, PBH, C_PROGRESS_BODY, C_PROGRESS_BRD)

    with p.overlay(name='abort'):
        p.footer("<Aborted: [msg$?]")
    with p.overlay(name="done"):
        p.footer("Done in [done$1:00]")

    with p.overlay(name="cc"):
        p.text('header', '>', "CC")

    with p.overlay(name="cv"):
        p.text('header', '>', "CV")

    with p.overlay(name="eta"):
        p.text('footer', '>', "ETA: [eta_time$1:10]")



PngPicture.save_pallete()
