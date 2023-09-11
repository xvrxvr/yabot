import colorsys
import png
import math
from yabot_pixs import pixels
from textwrap import wrap


class PngPicture(object):

    def __init__(self):
        self.screen = [966 * [255]]
        for row in range(240):
            self.screen.append([255, 255, 255] + (960 * [0]) + [255, 255, 255])
        self.screen.append(966 * [255])

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

    def write(self):
        fname = "rainbow.png"
        with open(fname, 'wb') as f:
            w = png.Writer(322, 242, greyscale=False)
            w.write(f, self.screen)


def get_scale(s, v):
    result = []
    for idx in range(360):
        r, g, b = colorsys.hsv_to_rgb(idx/360., s, v)
        result.append([int(r*31), int(g*31), int(b*31)])
    return result


sin_idx = []

pic = PngPicture()

scale = get_scale(1, 1)
scale2 = get_scale(0.7, 0.5)
for row, row_data in enumerate(pixels):
    idx = int(10 + 10* math.sin((row%80) * 2*math.pi / 80))
    sin_idx.append(str(idx*4))
    for col, pix in enumerate(row_data):
        sc = scale2 if pix != '.' else scale
        pic.put(col, row, sc[col+idx])

pic.write()

print """#include "common.h"

__code uint8_t start_logo_data[]={""";

for row in pixels:
    acc = []

    def app(counter):
        if counter >= 256:
            acc.extend([255, 0, counter-255])
        else:
            acc.append(counter)

    cur = ' '
    counter = 0
    for pix in row:
        if cur == pix:
            counter += 1
        else:
            app(counter)
            cur = pix
            counter = 1
    if counter:
        app(counter)
    print "{}, {},".format(len(acc), ','.join(str(x) for x in acc))

print "255};\n"


def cdata2palete(rgb):
    r, g, b = rgb
    b1 = (r<<3) | (g>>2)
    b2 = ((g<<6) & 0xC0) | b;
    if b2 & 0x40:
        b2 |= 0x20
    return ["0x{:02X}".format(b1), "0x{:02X}".format(b2)]

acc = []
for p1, p2 in zip(scale, scale2):
    acc += cdata2palete(p1)
    acc += cdata2palete(p2)

print '\n'.join(wrap("__code uint8_t logo_rainbow[] = {" + ", ".join(acc) + "};")), "\n"

print '\n'.join(wrap("__code uint8_t logo_sin[] = {" + ", ".join(sin_idx) + "};"))
