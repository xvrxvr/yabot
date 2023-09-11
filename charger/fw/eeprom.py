import serial

def read_eeprom():
    with serial.Serial("COM5", baudrate=115200) as s:
        return s.read(512*4)

image = read_eeprom()
with open('raw_image.bin', 'wb') as f:
    f.write(image)

print "Index:", ord(image[3])

print "CC mode:"
for i in range(0, 256):
    subr = image[i*4 : i*4+3]
    encoded = [ "-" if ord(v) == 0xFF else "{:3}".format(ord(v)) for v in subr]
    line = " ".join(encoded)
    if line == "- - -":
        continue
    print " {:4}V: {}".format((i+100)/10., line)

print "CV mode:"
for i in range(0, 256):
    subr = image[256+i*4 : 256+i*4+3]
    encoded = [ "-" if ord(v) == 0xFF else "{:3}".format(ord(v)) for v in subr]
    line = " ".join(encoded)
    if line == "- - -":
        continue
    n = ("{}000".format(i/100.))[0:4]
    print " {}A: {}".format(n, line)
