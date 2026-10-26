"""Ada görselinin kum ortasını gerçek ot dokulu çimene çevirir.
Kullanım: python3 asset_sources/mochi/grassify_base.py asset_sources/images/mochi-world-green.png 4
"""
import sys, math, random
import numpy as np
from PIL import Image, ImageFilter, ImageDraw
out_p=sys.argv[1]; step=float(sys.argv[2]) if len(sys.argv)>2 else 4.0
SRC='/Users/flywork/Projects/fastingapp/asset_sources/images/mochi-worlds.png'
random.seed(11)
im=Image.open(SRC).convert('RGB'); a=np.array(im).astype(float); H,W=a.shape[:2]
hsv=np.array(im.convert('HSV')).astype(float); h,s,v=hsv[...,0],hsv[...,1],hsv[...,2]
yy=np.arange(H)[:,None]
sand=(h>12)&(h<33)&(s>55)&(s<200)&(v>150)&(yy>690)&(yy<1125)
# Kıyıya yakın sarımsı geçiş bandı da (ön taraf) çimene dahil.
sand|=(h>=33)&(h<47)&(s>110)&(v>150)&(yy>900)&(yy<1115)
mI=Image.fromarray((sand*255).astype('uint8')).filter(ImageFilter.MinFilter(7)).filter(ImageFilter.MaxFilter(15))
m=np.array(mI.filter(ImageFilter.GaussianBlur(6))).astype(float)/255
lum=np.array(im.convert('L').filter(ImageFilter.GaussianBlur(10))).astype(float)
ls=np.median(lum[sand]); shade=(lum/ls).clip(0.6,1.25)

BASE=np.array([176,208,102.])
S=2
# zemin: bir tık koyu alt ton (otların arası)
ground=(BASE*0.80)[None,None,:]*np.ones((H,W,1))
canvas=Image.fromarray(ground.clip(0,255).astype('uint8')).resize((W*S,H*S))
d=ImageDraw.Draw(canvas)
ys,xs=np.where(np.array(mI)>0)
y0,y1,x0,x1=ys.min()-6,ys.max()+6,xs.min()-6,xs.max()+6
pal=[(0.78,0.82,0.70),(0.90,0.94,0.85),(1.0,1.0,1.0),(1.08,1.06,1.0),(1.16,1.12,0.92)]
def blade(x,y,L,w,col,tilt):
    cx=x+math.sin(tilt)*L*0.6+random.uniform(-1.5,1.5); cy=y-L*0.55
    ex=x+math.sin(tilt)*L; ey=y-math.cos(tilt)*L
    pts=[]
    for t in np.linspace(0,1,7):
        px=(1-t)**2*x+2*(1-t)*t*cx+t*t*ex; py=(1-t)**2*y+2*(1-t)*t*cy+t*t*ey
        pts.append((px*S,py*S))
    for i in range(len(pts)-1):
        ww=max(1,int(w*S*(1-i/len(pts))*1.2))
        d.line([pts[i],pts[i+1]],fill=col,width=ww)
y=y0
while y<y1:
    x=x0+random.uniform(0,step)
    while x<x1:
        jx=x+random.uniform(-step*0.5,step*0.5); jy=y+random.uniform(-step*0.5,step*0.5)
        if 0<=int(jy)<H and 0<=int(jx)<W and m[int(jy),int(jx)]>0.05:
            n=random.choice((1,1,2,3))
            for _ in range(n):
                f=random.choice(pal); var=random.uniform(0.95,1.05)
                col=tuple(int(min(255,BASE[i]*f[i]*var)) for i in range(3))
                # perspektif: önde (aşağıda) otlar biraz daha uzun
                persp=0.8+0.5*(jy-690)/430
                blade(jx+random.uniform(-1.5,1.5),jy,random.uniform(4,8)*persp,random.uniform(1.0,1.8),col,random.uniform(-0.6,0.6))
        x+=step
    y+=step*0.8
g=np.array(canvas.resize((W,H),Image.LANCZOS).filter(ImageFilter.GaussianBlur(0.6))).astype(float)
g=g*shade[...,None]
out=a*(1-m[...,None])+g.clip(0,255)*m[...,None]
Image.fromarray(out.astype('uint8')).save(out_p)
