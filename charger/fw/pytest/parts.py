import plotly.graph_objects as go

import time
from datetime import datetime, timedelta
from collections import namedtuple

S_2_56 = 1
S_1_28 = 2
S_640 = 4
S_320 = 8
S_160 = 16
S_80 = 32
S_40 = 64
S_20 = 128

def voltage(value, scale, mult):
    result = value = value*2.1*mult/scale/65536
    suf = "V"
    if value < 0.05:
        value *= 1000
        suf = "mV"
    return result, "{:.2f}{}".format(value, suf)

def V(value, scale, mult=1, shift=0, m2=1):
    result, img = voltage(value-shift, scale, mult*m2)
    return result, "{} ({})".format(img, value)

def I(value):
    result = current = value/14218.0
    suf = "A"
    if current < 0.05:
        current *= 1000
        suf = "mA"
    return result, "{:.2f}{} ({})".format(current, suf, value)


CHARTS = "Zero,FullBat,BT1,BT2,BT3,BT4,CurrentSence,Input,BL1,BL2,BL3,BL4,CC_CV,ChargePathSence,V_Adjust,Mode".split(",")
ChartData = namedtuple("ChartData", CHARTS)

class TraceData:
    def __init__(self, ts):
        self.ts = ts
        self.lines = []
        self.str_lines = []
        self.duration = 0

    def add_line(self, line, m2=1):
        line[-1] = 1 if line[-1] == "+" else 0
        data = [int(x) for x in line]
        data = ChartData(*data)

        Zero, ZeroStr = V(data.Zero, S_20, 1, 0x8000)
        Input, InputStr = V(data.Input,   S_2_56, 10)
        FullBat, FullBatStr = V(data.FullBat, S_2_56, 10, m2=m2)
        CurrentSence, CurrentSenceStr = I(data.CurrentSence)

        BT1, BT1Str = V(data.BT1, S_640, 10, m2=m2)
        BT2, BT2Str = V(data.BT2, S_640, 10, m2=m2)
        BT3, BT3Str = V(data.BT3, S_640, 10, m2=m2)
        BT4, BT4Str = V(data.BT4, S_640, 10, m2=m2)
              
        BL1, BL1Str = V(data.BL1, S_640, 10)
        BL2, BL2Str = V(data.BL2, S_640, 10)
        BL3, BL3Str = V(data.BL3, S_640, 10)
        BL4, BL4Str = V(data.BL4, S_640, 10)

        CC_CV, CC_CVStr = V(data.CC_CV, S_2_56, 10, 0x8000)
        ChargePathSence, ChargePathSenceStr = V(data.ChargePathSence, S_2_56, 1, 0x8000)
        V_Adjust, V_AdjustStr = data.V_Adjust/10, data.V_Adjust

        Mode = data.Mode
        
        self.lines.append(ChartData(
            Zero=Zero,
            FullBat=FullBat,
            BT1=BT1,
            BT2=BT2,
            BT3=BT3,
            BT4=BT4,
            CurrentSence=CurrentSence,
            Input=Input,
            BL1=BL1,
            BL2=BL2,
            BL3=BL3,
            BL4=BL4,
            CC_CV=CC_CV,
            ChargePathSence=ChargePathSence,
            V_Adjust=V_Adjust,
            Mode=Mode
        ))

        self.str_lines.append(f"Zero={ZeroStr}\nInput={InputStr}; FullBat={FullBatStr}\nCurrentSence={CurrentSenceStr}<br>"
        f"BT={BT1Str}/{BT2Str}/{BT3Str}/{BT4Str}\nBL={BL1Str}/{BL2Str}/{BL3Str}/{BL4Str}<br>"
        f"CC_CV={CC_CVStr}; ChargePathSence={ChargePathSenceStr}; V_Adjust={V_AdjustStr}<br>Charge is {Mode}")

    def _decode(self):
        total = len(CHARTS)
        result = [[] for _ in range(total)]
        for idx in range(total):
            for line in self.lines:
                result[idx].append(line[idx])
        return result

    def show(self):
        datas = self._decode()
        print(self)
        fig = go.Figure()
        for data, chart_name in zip(datas, CHARTS):
            if chart_name[0] == 'B':
                legendgroup = chart_name[:2]
            else:
                legendgroup = None
            fig.add_trace(go.Scatter(y=data, mode='lines+markers', name=chart_name, text=self.str_lines, legendgroup=legendgroup))
        fig.show()

    def __str__(self):
        return "Trace from {} with {} items (duration is {})".format(datetime.fromtimestamp(self.ts), len(self.lines), timedelta(seconds=int(self.duration)))

def load_trace(fname):
    result = []
    with open(fname, "r") as f:
        td = None
        m2 = 1
        for line in f:
            # 1578124794.16:!
            # 0.932999849319:D:65535,39721,24472,65535,65535,65535,1,4986,24457,65535,65535,65535,43037,33062,0,-
            splited = line.strip().split(':')
            if splited[1] == '!':
                td = TraceData(float(splited[0]))
                result.append(td)
                if len(result) >= 10:
                    m2 = 1.01
            elif splited[1] == 'D':
                td.add_line(splited[2].split(','), m2)
                td.duration = float(splited[0])
    return result

all_traces = load_trace("Z:/home/roman/yabot/charger/fw/trace.txt")
for idx, p in enumerate(all_traces):
    print("all_traces[{}] {}".format(idx, p))

def S(idx):
    all_traces[idx].show()
