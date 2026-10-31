from PIL import Image, ImageDraw, ImageFont
from pathlib import Path

OUT = Path(__file__).resolve().parent
S = 2
W, H = 1440, 1300
im = Image.new('RGB', (W*S, H*S), '#EDF0F3')
d = ImageDraw.Draw(im)
REG = 'C:/Windows/Fonts/msyh.ttc'
BOLD = 'C:/Windows/Fonts/msyhbd.ttc'
C = dict(ink='#111827', secondary='#4B5563', muted='#6B7280', line='#E5E7EB', bg='#F9FAFB', white='#FFFFFF', red='#DC2626', green='#16A34A')

def font(size, bold=False):
    return ImageFont.truetype(BOLD if bold else REG, int(size*S))

def rect(box, fill, radius=0, outline=None, width=1):
    box = tuple(int(v*S) for v in box)
    if radius:
        d.rounded_rectangle(box, radius=int(radius*S), fill=fill, outline=outline, width=int(width*S))
    else:
        d.rectangle(box, fill=fill, outline=outline, width=int(width*S))

def line(points, fill=C['line'], width=1):
    d.line([(int(x*S), int(y*S)) for x,y in points], fill=fill, width=max(1,int(width*S)), joint='curve')

def text(x,y,s,size=14,fill=C['ink'],bold=False,anchor=None):
    d.text((int(x*S),int(y*S)),s,font=font(size,bold),fill=fill,anchor=anchor,stroke_width=0)

def tw(s,size=14,bold=False):
    return d.textlength(s,font=font(size,bold))/S

def centered(cx,y,s,size=14,fill=C['ink'],bold=False):
    text(cx-tw(s,size,bold)/2,y,s,size,fill,bold)

def icon(kind,x,y,color=C['secondary'],size=20):
    z=size/20
    def pts(a): return [(x+u*z,y+v*z) for u,v in a]
    if kind=='back': line(pts([(12,4),(6,10),(12,16)]),color,1.7); line(pts([(6,10),(18,10)]),color,1.7)
    elif kind=='search':
        d.ellipse(tuple(int(v*S) for v in (x+3*z,y+2*z,x+14*z,y+13*z)),outline=color,width=int(1.7*S))
        line(pts([(13,12),(18,17)]),color,1.7)
    elif kind=='restore':
        d.arc(tuple(int(v*S) for v in (x+4*z,y+4*z,x+17*z,y+17*z)),205,510,fill=color,width=int(1.6*S))
        line(pts([(3,4),(3,10),(9,10)]),color,1.6)
    elif kind=='trash':
        line(pts([(4,6),(16,6)]),color,1.6)
        line(pts([(7,6),(7,3),(13,3),(13,6)]),color,1.6)
        line(pts([(5,6),(6,17),(14,17),(15,6)]),color,1.6)
        line(pts([(9,9),(9,14)]),color,1.5); line(pts([(12,9),(12,14)]),color,1.5)
    elif kind=='info':
        d.ellipse(tuple(int(v*S) for v in (x+2*z,y+2*z,x+18*z,y+18*z)),outline=color,width=int(1.4*S))
        line(pts([(10,9),(10,14)]),color,1.5)
        rect((x+9.3*z,y+5.5*z,x+10.7*z,y+7*z),color,1)
    elif kind=='check': line(pts([(4,10),(8,14),(16,6)]),color,2)
    elif kind=='down':
        line(pts([(10,3),(10,17)]),color,1.4);line(pts([(6,13),(10,17),(14,13)]),color,1.4)

def button(x,y,w,h,label,kind='outline',ico=None):
    bg = C['ink'] if kind=='primary' else C['red'] if kind=='danger' else C['white']
    fg = C['white'] if kind in ['primary','danger'] else C['red'] if kind=='danger-outline' else C['ink']
    border = None if kind in ['primary','danger'] else '#FECACA' if kind=='danger-outline' else C['line']
    rect((x,y,x+w,y+h),bg,10,border)
    if ico:
        span=18+6+tw(label,14,True)
        start=x+(w-span)/2
        icon(ico,start,y+(h-18)/2,fg,18)
        text(start+24,y+(h-20)/2-1,label,14,fg,True)
    else: centered(x+w/2,y+(h-20)/2-1,label,14,fg,True)

def pill(x,y,label,selected=False):
    rect((x,y,x+20,y+20),C['ink'] if selected else C['white'],6,None if selected else '#D1D5DB')
    if selected: icon('check',x+2,y+2,C['white'],16)

def status(x,y):
    text(x+25,y+12,'9:41',13,C['ink'],True)
    for i,h in enumerate([4,6,8,10]): rect((x+303+i*4,y+23-h,x+305+i*4,y+23),C['ink'],1)
    d.arc(tuple(int(v*S) for v in (x+324,y+13,x+340,y+28)),220,320,fill=C['ink'],width=3)
    d.arc(tuple(int(v*S) for v in (x+328,y+17,x+336,y+26)),220,320,fill=C['ink'],width=3)
    rect((x+349,y+15,x+370,y+25),C['white'],3,C['ink'])
    rect((x+351,y+17,x+366,y+23),C['ink'],1)
    rect((x+371,y+18,x+373,y+22),C['ink'],1)

DATA=[('伟','张伟','收礼','婚礼','+500.00','婚礼礼簿','10月18日','#FDF2F8','#DB2777'),
      ('敏','周敏','送礼','乔迁','−800.00','日常往来','10月12日','#EFF6FF','#2563EB'),
      ('婷','孙婷','收礼','生日','+200.00','日常往来','10月08日','#FAF5FF','#9333EA'),
      ('洋','刘洋','送礼','婚礼','−600.00','日常往来','09月28日','#FFF7ED','#EA580C')]

def record(x,y,item,select=False,checked=False,last=False):
    initial,name,direction,event,amount,book,date,soft,accent=item
    if checked: rect((x,y,x+361,y+118),'#F3F4F6',0)
    if select:
        pill(x+14,y+22,'',checked)
        tx=x+48
    else:
        rect((x+14,y+17,x+54,y+57),soft,20)
        centered(x+34,y+23,initial,20,accent,True)
        tx=x+66
    text(tx,y+16,name,16,C['ink'],True)
    amount_color=C['green'] if direction=='收礼' else '#EF4444'
    text(x+347-tw(amount,16,True),y+16,amount,16,amount_color,True)
    text(tx,y+43,f'{direction}  /  {event}',13,C['secondary'])
    text(tx,y+65,f'{book}  ·  {date}',11,C['muted'])
    text(tx,y+86,'今天 10:24 删除' if name=='张伟' else '今天 09:16 删除' if name=='周敏' else '昨天 18:32 删除',11,C['muted'])
    if not select: button(x+279,y+63,68,44,'恢复',ico=None)
    if not last: line([(x+14,y+118),(x+347,y+118)],'#F0F1F3')

def phone(x,y,selected=False):
    # Device boundary is deliberately quiet: the interface is the focus.
    rect((x-2,y-2,x+395,y+854),'#D6DCE2',29)
    rect((x,y,x+393,y+852),C['bg'],27)
    rect((x+1,y+29,x+392,y+89),C['white'])
    status(x,y)
    icon('back',x+17,y+51,C['ink'],21)
    centered(x+196.5,y+48,'已选择 2 项' if selected else '回收站',19,C['ink'],True)
    text(x+343,y+51,'取消' if selected else '选择',14,C['secondary'],True)
    icon('info',x+17,y+111,C['muted'],18)
    text(x+44,y+108,'删除的内容可在这里恢复',13,C['secondary'])
    text(x+44,y+130,'彻底删除后无法找回',12,C['muted'])
    rect((x+16,y+167,x+377,y+215),'#EEF0F2',12)
    rect((x+20,y+171,x+195,y+211),C['white'],9)
    centered(x+108,y+181,'收支记录  8',14,C['ink'],True)
    centered(x+285,y+181,'联系人  3',14,C['muted'])
    rect((x+16,y+231,x+377,y+275),C['white'],11,C['line'])
    icon('search',x+29,y+243,'#9CA3AF',18)
    text(x+56,y+242,'搜索姓名、事由、账簿',13,'#9CA3AF')
    text(x+17,y+297,'今天删除',12,C['muted'],True)
    if selected:
        pill(x+290,y+298,'',False)
        text(x+319,y+297,'全选',12,C['secondary'])
    else:
        text(x+288,y+297,'最新删除',12,C['muted'])
        icon('down',x+348,y+297,C['muted'],15)
    rect((x+16,y+326,x+377,y+562),C['white'],15,C['line'])
    record(x+16,y+326,DATA[0],selected,selected,False)
    record(x+16,y+444,DATA[1],selected,selected,True)
    # Restore rounded edges after the selection tint.
    if selected:
        line([(x+31,y+326),(x+362,y+326)],C['line'])
    text(x+17,y+582,'昨天删除',12,C['muted'],True)
    rect((x+16,y+612,x+377,y+730),C['white'],15,C['line'])
    record(x+16,y+612,DATA[2],selected,False,True)
    if not selected:
        centered(x+196.5,y+758,'已按删除时间由近到远排列',11,'#9CA3AF')
    else:
        rect((x+1,y+752,x+392,y+828),C['white'])
        line([(x+1,y+752),(x+392,y+752)],C['line'])
        button(x+16,y+768,143,44,'彻底删除',kind='danger-outline',ico='trash')
        button(x+171,y+768,206,44,'恢复 2 项',kind='primary',ico='restore')
    rect((x+139,y+836,x+254,y+840),C['ink'],3)

text(64,38,'礼记 / 回收站',34,C['ink'],True)
text(64,94,'重构设计提案',16,C['secondary'])
text(64,124,'让误删后的找回更直接，让彻底删除更明确。',14,C['muted'])
text(1180,48,'界面设计稿',13,C['secondary'])
text(1180,72,'浅色模式 · 示例数据',12,C['muted'])
line([(64,167),(1376,167)],'#D8DEE5')

positions=[64,523,982]
for x,title,desc in zip(positions,['默认浏览','批量选择','彻底删除确认'],['先找到内容，再恢复','长按条目或点击「选择」进入','明确对象、数量与不可恢复后果']):
    text(x,184,title,17,C['ink'],True)
    text(x,212,desc,12,C['muted'])

Y=250
phone(positions[0],Y,False)
phone(positions[1],Y,True)
phone(positions[2],Y,True)

# A real modal treatment for the destructive action.
x=positions[2]
overlay=Image.new('RGBA',im.size,(0,0,0,0))
od=ImageDraw.Draw(overlay)
od.rounded_rectangle(tuple(int(v*S) for v in (x,Y,x+393,Y+852)),radius=27*S,fill=(17,24,39,92))
im=Image.alpha_composite(im.convert('RGBA'),overlay).convert('RGB')
d=ImageDraw.Draw(im)
mx,my=x+24,Y+237
rect((mx,my,mx+345,my+352),C['white'],16)
rect((mx+20,my+22,mx+60,my+62),'#FEE2E2',12)
icon('trash',mx+29,my+30,C['red'],23)
text(mx+20,my+80,'彻底删除这 2 条记录？',19,C['ink'],True)
text(mx+20,my+115,'删除后无法恢复，请确认已不再需要。',12,C['secondary'])
rect((mx+20,my+151,mx+325,my+240),C['bg'],10)
text(mx+33,my+165,'张伟 · 婚礼',13,C['ink'])
text(mx+222,my+165,'收礼 ¥500',13,C['secondary'])
line([(mx+33,my+195),(mx+312,my+195)],C['line'])
text(mx+33,my+207,'周敏 · 乔迁',13,C['ink'])
text(mx+222,my+207,'送礼 ¥800',13,C['secondary'])
text(mx+20,my+254,'对应联系人将保留。',12,C['muted'])
button(mx+20,my+291,146,44,'取消')
button(mx+178,my+291,147,44,'彻底删除',kind='danger')

# Handoff notes are outside the product UI.
notes=[('恢复放在手边','保留姓名、金额、事由和原账簿；','移除重复的大按钮，增加可见条目。'),
       ('操作收在底部','选择后统一恢复或彻底删除；','保持分类范围，明确选中数量。'),
       ('删除前看清影响','记录删除确认展示名称与金额；','联系人删除需另列关联记录影响。')]
for x,(title,a,b) in zip(positions,notes):
    text(x,1130,title,15,C['ink'],True)
    text(x,1160,a,12,C['secondary'])
    text(x,1182,b,12,C['secondary'])
line([(64,1227),(1376,1227)],'#D8DEE5')
text(64,1245,'设计范围：回收站页面与操作状态。沿用礼记现有配色、字体层级、16px 页面留白和 44px 最小触控区。',12,C['muted'])
text(64,1267,'本图为重构提案：搜索、批量操作与时间分组需后续实现；不设定自动清理期限。',11,C['muted'])

OUT.mkdir(parents=True,exist_ok=True)
im.save(OUT/'recycle-bin-redesign.png',optimize=True)
print(OUT/'recycle-bin-redesign.png')
