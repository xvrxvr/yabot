import sys

pins = int(sys.argv[1])

outf = open("bhr%d.au3" % (pins*2),"wt")

print >> outf, """
WinActivate("P-CAD 2006 Pattern Editor")
WinWaitActive("P-CAD 2006 Pattern Editor")
"""

def wr_line(points):
    acc = 'Send("!al'
    for x, y in points:
        acc += "j%s{TAB}%s{ENTER}" % (x, y)
    print >> outf, acc+'{ESC}")'

def wr_line_rel(org, *points):
    new_points = [org]
    org = [ org[0], org[1] ]
    for p in points:
        if 'x' in p:
            org[0] += p['x']
        elif 'y' in p:
            org[1] += p['y']
        else:
            wr_line(new_points)
            if 'sx' in p:
                org[0] += p['sx']
            else:
                org[1] += p['sy']
            new_points = [org[:]]
            continue
        new_points.append(tuple(org))
    if new_points:
        wr_line(new_points)


L = pins*2.54+7.6
L2 = L/2

wr_line_rel( (-5.07, -2.46),
 {'x': L},
 {'y': -9},
 {'x': -(L2-1)},
 {'y': 2},
 {'x': -2},
 {'y': -2},
 {'x': -(L2-1)},
 {'y': 9}
)
wr_line_rel( (-5.07, -11.46),
 {'y': -13.6},
 {'x': L},
 {'y': 13.6}
)

line = 'Send("!ap{ENTER}'

for idx in range(pins):
    line += "j%s{TAB}0{ENTER}" % (idx*2.54)
    line += "j%s{TAB}2.54{ENTER}" % (idx*2.54)

print >>outf, line+'")'

print >>outf, 'Send("!ar{ENTER}j0{TAB}0{ENTER}")'
print >>outf, 'Send("!abRefDes{ENTER}j%s{TAB}4{ENTER}")' % (pins*1.25-1.25)
print >>outf, 'Send("!abType{ENTER}j%s{TAB}-3{ENTER}")' % (pins*1.25-1.25)
print >>outf, 'Send("!abValue{ENTER}j%s{TAB}0{ENTER}")' % (pins*2.54+2.5)
