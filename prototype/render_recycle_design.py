from PIL import Image, ImageDraw, ImageFont
from pathlib import Path
S=2
im=Image.new('RGB',(3160,2360),'#EEF0F3');d=ImageDraw.Draw(im)
def txt(x,y,s,n=14,c='#20242C',b=False):d.text((x*S,y*S),s,font=ImageFont.truetype('C:/Windows/Fonts/msyhbd.ttc' if b else 'C:/Windows/Fonts/msyh.ttc',n*S),fill=c)
def rect(x,y,w,h,c='#FFFFFF',r=12,o=None):d.rounded_rectangle((x*S,y*S,(x+w)*S,(y+h)*S),r*S,fill=c,outline=o,width=2)
def ln(x,y,X,Y,c='#DCE1E8',w=1):d.line((x*S,y*S,X*S,Y*S),fill=c,width=w*S)
def circle(x,y,r,c,o=None):d.ellipse(((x-r)*S,(y-r)*S,(x+r)*S,(y+r)*S),fill=c,outline=o,width=2)
def check(x,y,on):
 circle(x,y,9,'#20242C' if on else '#FFFFFF','#20242C' if on else '#C7CED8')
 if on:ln(x-4,y,x-1,y+3,'#FFFFFF',2);ln(x-1,y+3,x+5,y-4,'#FFFFFF',2)
txt(64,30,'尚礼 / 回收站重构',30,b=True);txt(64,80,'以找回为主线，让内容更好辨认，让关联影响更早被看见。',16,'#657082')
rect(1310,40,205,34);txt(1328,48,'移动端设计提案 · 01',13,'#657082')
for mode,x in enumerate([64,593,1122]):
 y=178
 txt(x,124,['01 / 收支记录','02 / 联系人','03 / 批量操作'][mode],18,b=True)
 txt(x,152,['快速定位误删内容，单条恢复一步可达','提前说明关联记录，减少恢复后的疑惑','固定操作区，始终看得见选中数量'][mode],12,'#748092')
 rect(x-5,y-5,403,862,'#DADEE5',35);rect(x,y,393,852,'#F8F9FB',31)
 txt(x+24,y+14,'9:41',12,b=True)
 for k,h in enumerate([4,7,10,13]):rect(x+317+k*5,y+29-h,3,h,'#20242C',1)
 rect(x+346,y+17,22,12,'#FFFFFF',3,'#20242C');rect(x+349,y+20,15,6,'#20242C',1)
 ln(x+22,y+68,x+29,y+61,'#20242C',2);ln(x+22,y+68,x+29,y+75,'#20242C',2)
 txt(x+158,y+54,'回收站',20,b=True);txt(x+339,y+60,'取消' if mode==2 else '选择',14,'#505B6B')
 rect(x+16,y+104,361,47,'#EFF1F4');circle(x+36,y+127,7,'#EFF1F4','#788494');txt(x+34,y+118,'i',11,'#788494',True);txt(x+55,y+112,'删除的内容可恢复',12,'#5A6576');txt(x+55,y+130,'彻底删除后无法找回',10,'#8590A0')
 rect(x+16,y+167,361,47,'#EDEFF3');rect(x+20+(178 if mode==1 else 0),y+171,175,39)
 txt(x+47,y+181,'收支记录  12',14,'#7D8797' if mode==1 else '#20242C',mode!=1);txt(x+234,y+181,'联系人  3',14,'#20242C' if mode==1 else '#7D8797',mode==1)
 rect(x+16,y+229,361,44,o='#E6E9EE');circle(x+35,y+249,6,'#FFFFFF','#919EAE');ln(x+40,y+254,x+45,y+259,'#919EAE',2)
 txt(x+58,y+242,'搜索姓名、关系、电话' if mode==1 else '搜索姓名、事由、账簿',12,'#919BAA')
 if mode!=1:
  for j,s in enumerate(['全部','收礼','送礼']):
   rect(x+16+j*71,y+288,63,30,'#20242C' if j==0 else '#FFFFFF',15,'#E4E8EE');txt(x+34+j*71,y+295,s,11,'#FFFFFF' if j==0 else '#657082')
  txt(x+282,y+296,'最近删除 ↓',11,'#7A8697')
 else:txt(x+17,y+292,'按删除时间倒序',11,'#7A8697');txt(x+325,y+292,'共 3 位',11,'#7A8697')
 names=['张伟','李娜','王强'] if mode!=1 else ['李娜','陈晨','赵敏']
 ys=[363,479,646] if mode!=1 else [353,504,625]
 txt(x+17,y+(327 if mode==1 else 337),'今天',12,'#697588',True)
 for i,(name,yy) in enumerate(zip(names,ys)):
  X=x+16;Y=y+yy;linked=(mode!=1 and i==1);sel=mode==2 and i!=1
  if i==2 and mode!=1:txt(x+17,y+620,'昨天',12,'#697588',True)
  if i==1 and mode==1:txt(x+17,y+478,'更早',12,'#697588',True)
  rect(X,Y,361,123 if linked else (109 if mode==1 else 104),'#F0F3F7' if sel else '#FFFFFF',14,'#D9DFE7' if sel else '#E7EBF0')
  if mode==2:check(X+23,Y+29,sel);ox=X+45
  else:circle(X+29,Y+31,19,['#E8EDF5','#F2ECE7','#E8EFEB'][i]);txt(X+21,Y+19,name[0],16,'#647186',True);ox=X+59
  txt(ox,Y+14,name,16,b=True)
  if mode!=1:
   amount=['+2,000','−800','−1,200'][i];txt(X+239,Y+16,amount,16,'#24815C' if i==0 else '#B65B55',True)
   txt(ox,Y+40,['结婚礼金 · 家庭账簿','孩子满月 · 人情往来','乔迁之喜 · 家庭账簿'][i],11,'#6E7A8C')
   txt(ox,Y+70,['14:32 删除','10:18 删除','昨天 18:06 删除'][i],10,'#8D98A8')
  else:
   txt(ox,Y+41,['朋友 · 138 **** 6028','同事 · 139 **** 1826','亲戚'][i],12,'#6E7A8C');txt(ox,Y+74,['关联 2 条已删除记录','关联 1 条已删除记录','无已删除的关联记录'][i],10,'#8D98A8')
  if mode!=2:rect(X+283,Y+64,62,29,o='#DCE2E9');txt(X+302,Y+70,'恢复',11,'#475467',True)
  if linked:txt(ox,Y+98,'关联联系人已删除，恢复时将一并恢复',10,'#9A7540')
 if mode==1:txt(x+28,y+758,'恢复联系人后，收支记录需单独恢复',11,'#8390A1')
 if mode==2:
  rect(x,y+753,393,82,r=0);ln(x,y+753,x+393,y+753)
  check(x+28,y+774,False);txt(x+47,y+765,'全选',12,'#5E6B7D');txt(x+288,y+765,'已选 2 项',12,'#5E6B7D')
  rect(x+16,y+794,135,38,o='#E7CDCE');txt(x+54,y+804,'彻底删除',13,'#B45555',True)
  rect(x+163,y+794,214,38,'#20242C');txt(x+228,y+804,'恢复 2 项',13,'#FFFFFF',True)
 else:txt(x+125,y+803,'长按条目可批量选择',11,'#99A3B2')
 rect(x+145,y+839,103,4,'#20242C',2)
for x,title,desc in [(64,'压缩提示，突出内容','列表按删除日期分组，更快找到刚删的内容。'),(593,'明确恢复范围','恢复记录可连带联系人；联系人恢复不带记录。'),(1122,'区分操作权重','突出恢复，彻底删除前需确认关联影响。')]:
 txt(x,1074,title,17,b=True);txt(x,1110,desc,12,'#657082')
txt(64,1150,'示例数据 · 沿用当前黑白灰主题 · 收礼 / 送礼为建议新增筛选 · 不引入自动清理规则',12,'#8390A1')
im.save(r'E:\NewShangli\prototype\recycle-bin-redesign.png')
