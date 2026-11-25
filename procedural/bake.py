"""Bake modular indexed-by-surface scenery using only Python's standard library."""
import math, random, json, struct, pathlib
from math import sin, cos, pi
from collections import defaultdict
root=pathlib.Path(__file__).resolve().parents[1]
rng=random.Random(1739)
surfaces=defaultdict(list)
def tri(a,b,c,col,s='Stone'):
    surfaces[s].append((a,b,c,col))
def tint(col,f):
    return tuple(min(1,c*f) for c in col)
def tube(rings,col,s='Stone',jitter=.08):
    for low,high in zip(rings,rings[1:]):
        for i,a in enumerate(low):
            k=(i+1)%len(low); color=tint(col,rng.uniform(1-jitter,1+jitter))
            tri(a,high[i],low[k],color,s);tri(low[k],high[i],high[k],color,s)
    for row,rev in [(rings[0],False),(rings[-1],True)]:
        for i in range(1,len(row)-1):
            tri(row[0],row[i+int(rev)],row[i+1-int(rev)],col,s)
def ring(x,y,z,rx,rz,n,phase=0):
    return [(x+rx*cos(2*pi*i/n+phase),y,z+rz*sin(2*pi*i/n+phase)) for i in range(n)]
def bulb(x,y,z,rx,ry,rz,col,s='Stone',n=10):
    tube([ring(x,y+ry*sin(a),z,rx*max(.015,cos(a)),rz*max(.015,cos(a)),n) for a in (-1.55,-.82,-.22,.39,.95,1.55)],col,s)
def beam(a,b,r,end,col,n=8,s='Stone'):
    v=[b[i]-a[i] for i in range(3)]; l=math.hypot(*v);v=[t/l for t in v]
    def cross(u,w):return (u[1]*w[2]-u[2]*w[1],u[2]*w[0]-u[0]*w[2],u[0]*w[1]-u[1]*w[0])
    u=cross(v,(0,0,1) if abs(v[2])<.9 else (1,0,0));l=math.hypot(*u);u=[t/l for t in u];w=cross(u,v)
    tube([[tuple(p[j]+rad*(u[j]*cos(2*pi*i/n)+w[j]*sin(2*pi*i/n)) for j in range(3)) for i in range(n)] for p,rad in [(a,r),(b,end)]],col,s)
def block(x,y,z,dx,dy,dz,col):
    def rim(k,h):
        return [(x+dx*a*k,y+h,z+dz*b*k) for a,b in [(-.44,-.5),(.44,-.5),(.5,-.41),(.5,.41),(.44,.5),(-.44,.5),(-.5,.41),(-.5,-.41)]]
    tube([rim(.94,-dy/2),rim(1,-dy*.38),rim(1,dy*.38),rim(.94,dy/2)],col)
grass=(.32,.63,.046);rock=(.36,.31,.29);wood=(.38,.16,.047);rope=(.65,.39,.13);stone=(.48,.49,.39)
def bake(name):
    blob=bytearray(); views=[];acc=[]; prim=[]; mats=[]
    def data(raw,count,typ,ct,**kw):
        while len(blob)%4:blob.append(0)
        views.append(dict(buffer=0,byteOffset=len(blob),byteLength=len(raw)));blob.extend(raw)
        acc.append(dict(bufferView=len(views)-1,componentType=ct,count=count,type=typ,**kw));return len(acc)-1
    for surface,faces in surfaces.items():
        pos=[];norm=[]; colors=bytearray()
        for a,b,c,col in faces:
            u=[y-x for x,y in zip(a,b)];v=[y-x for x,y in zip(a,c)]
            no=(u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]);ln=math.hypot(*no) or 1
            for p in (a,b,c):
                pos.extend(p);norm.extend(t/ln for t in no);colors.extend([int(max(0,min(1,f))*255) for f in col]+[255])
        count=len(pos)//3
        attrs=dict(POSITION=data(struct.pack('<%df'%len(pos),*pos),count,'VEC3',5126,min=[min(pos[i::3]) for i in range(3)],max=[max(pos[i::3]) for i in range(3)]),NORMAL=data(struct.pack('<%df'%len(norm),*norm),count,'VEC3',5126),COLOR_0=data(colors,count,'VEC4',5121,normalized=True))
        prim.append(dict(attributes=attrs,material=len(mats)));mats.append(dict(name=surface,doubleSided=True,pbrMetallicRoughness=dict(metallicFactor=0,roughnessFactor=.88)))
    j=dict(asset=dict(version='2.0'),scene=0,scenes=[dict(nodes=[0])],nodes=[dict(mesh=0,name=name)],meshes=[dict(primitives=prim)],materials=mats,buffers=[dict(byteLength=len(blob))],bufferViews=views,accessors=acc)
    raw=json.dumps(j).encode();raw+=b' '*(-len(raw)%4);blob+=bytes(-len(blob)%4)
    (root/'environment'/f'{name}.glb').write_bytes(struct.pack('<4sIIII',b'glTF',2,28+len(raw)+len(blob),len(raw),0x4e4f534a)+raw+struct.pack('<II',len(blob),0x004e4942)+blob);surfaces.clear()
def island(rx,rz,detail):
    n=34 if detail else 16
    outline=[rng.uniform(.93,1.02) for _ in range(n)]
    def layer(y,k,noise):
        return [(rx*k*cos(i*2*pi/n)*f,y+rng.uniform(-noise,noise),rz*k*sin(i*2*pi/n)*f) for i,f in enumerate(outline)]
    rows=[layer(-5,.14,.65),layer(-3.3,.57,.4),layer(-1.4,.87,.32),layer(-.28,1,.12)]
    tube(rows,rock,jitter=.28);tube([rows[-1],layer(.015,1,0)],grass)
    for i in range(n):
        a=i*2*pi/n
        bulb(rx*.88*cos(a),-1.05,rz*.88*sin(a),rx*.16,rng.uniform(.7,1.45),rz*.19,tint(rock,rng.uniform(.75,1.2)),n=6)
    if detail:
        for _ in range(470):
            a=rng.uniform(0,2*pi);k=rng.uniform(.83,.99);x=rx*k*cos(a);z=rz*k*sin(a)
            for j in range(3):
                h=rng.uniform(.12,.42);w=.035
                tri((x-w,0,z),(x+w,0,z),(x+rng.uniform(-.13,.13),h,z+.025),tint(grass,rng.uniform(.72,1.5)),'Foliage')
        for i in range(75):
            a=rng.uniform(0,2*pi);x=rx*.97*cos(a);z=rz*.97*sin(a)
            for k in range(rng.randrange(3,12)):
                xx=x+.09*sin(k*.7+i);yy=-k*.14
                tri((xx,yy,z),(xx+.16,yy-.06,z+.05),(xx+.085,yy-.26,z+.04),tint(grass,rng.uniform(.55,1.1)),'Foliage')
island(6,2.7,True);bake('Meadow')
island(4,2,False);bake('Horizon')
def tree():
    bark=(.24,.105,.039)
    for i in range(7):
        a=i*.9;beam((cos(a)*1.5,.04,sin(a)),(0,1,0),.07,.42,bark)
    beam((0,0,0),(-.24,2.3,0),.6,.41,bark);beam((-.24,2.2,0),(.25,3.9,.1),.44,.26,bark)
    for i in range(13):
        a=i*2.4;rr=rng.uniform(1.2,2.6);x=cos(a)*rr;z=sin(a)*rr*.7;y=4.3+rng.uniform(-.5,.8)
        beam((-.16,2.5+i*.07,0),(x*.64,y-.65,z*.64),.23,.13,bark)
        beam((x*.64,y-.65,z*.64),(x,y,z),.14,.06,bark)
        for j in range(5):
            bulb(x+rng.uniform(-.6,.6),y+rng.uniform(-.2,.45),z+rng.uniform(-.55,.55),.85,.45,.77,rng.choice([(.64,.064,.024),(.85,.16,.024),(.49,.038,.045),(.9,.25,.044)]),'Foliage',8)
tree()
for i in range(210):
    a=rng.uniform(0,2*pi);r=rng.uniform(.6,2.65);x=r*cos(a);z=r*sin(a)*.76;y=4.3+rng.uniform(-.3,.7)
    for j in range(4):
        u=a+j*1.4;dx=.23*cos(u);dz=.23*sin(u);col=rng.choice([(.78,.065,.025),(.92,.18,.024),(.99,.31,.036)])
        mid=(x+dx*.45,y+.038,z+dz*.45); tip=(x+dx,y-.10,z+dz)
        tri((x,y,z),(mid[0]-dz*.33,y,mid[2]+dx*.33),tip,col,'Foliage')
        tri((x,y,z),tip,(mid[0]+dz*.33,y,mid[2]-dx*.33),tint(col,.82),'Foliage')
# Curving bark ridges and ivy on the shaded side of the trunk.
for i in range(15):
    a=i*2*pi/15;old=None
    for j in range(14):
        t=j/13;cx=-.24*t*1.6 if t<.62 else -.24+(t-.62)*1.17
        r=.55-.30*t;ang=a+.24*sin(t*5+i)
        pt=(cx+r*cos(ang),t*3.82,r*sin(ang))
        if old:beam(old,pt,.046*(1-.64*t),.044*(1-.64*t),(.28,.12,.046) if i%2 else (.15,.061,.025),5)
        old=pt
for i in range(11):
    a=i*2.399;x=cos(a)*1.83;z=sin(a)*1.29;length=rng.uniform(.5,1.9)
    old=(x,4.50,z)
    for j in range(1,10):
        t=j/9;pt=(x+.12*sin(t*4+i),4.50-t*length,z+.055*t)
        beam(old,pt,.017,.016,(.23,.31,.035),5)
        side=1 if j%2 else -1
        tri(pt,(pt[0]+side*.13,pt[1]-.035,pt[2]+.05),(pt[0]+side*.078,pt[1]-.19,pt[2]+.03),(.25,.46,.052),'Foliage')
        old=pt
bake('Maple')
for i in range(5):
    a=i*2.4
    for j in range(7):
        b=j*2*pi/7
        bulb(cos(b)*.085+cos(a)*.19,.32+i*.019,sin(b)*.085+sin(a)*.19,.075,.036,.07,(.83,.16,.53) if i%2 else (.96,.83,.43),'Foliage',5)
    beam((0,0,0),(cos(a)*.19,.33+i*.019,sin(a)*.19),.014,.012,grass)
    bulb(cos(a)*.19,.36+i*.019,sin(a)*.19,.048,.035,.048,(1,.52,.02),n=6)
bake('Blossoms')
for i in range(7):
    block(0,.17+i*.34,0,.75 if i in (0,6) else .58,.33,.73 if i in (0,6) else .56,tint(stone,rng.uniform(.76,1.13)))
bake('Pillar')
for side in [-1,1]:
    for j in range(4):block(side*1.45,.21+j*.42,0,.58,.41,.77,stone)
for i in range(13):
    a=pi*i/13+.014;b=pi*(i+1)/13-.014
    pts=[(r*cos(t),1.68+r*sin(t)) for r,t in [(1.17,a),(1.73,a),(1.73,b),(1.17,b)]]
    tube([[(x,y,z) for x,y in pts] for z in [.38,-.38]],tint(stone,rng.uniform(.78,1.12)))
bake('Arch')
# Keep the existing scenery deterministic while reusing the arch's masonry.
arch_rng_state = rng.getstate()
for side, courses in [(-1, 4), (1, 2)]:
    for j in range(courses):
        block(side*1.45,.21+j*.42,0,.58,.41,.77,stone)
for i in range(9,13):
    a=pi*i/13+.014;b=pi*(i+1)/13-.014
    pts=[(r*cos(t),1.68+r*sin(t)) for r,t in [(1.17,a),(1.73,a),(1.73,b),(1.17,b)]]
    tube([[(x,y,z) for x,y in pts] for z in [.38,-.38]],tint(stone,rng.uniform(.78,1.12)))
block(.62,.17,.26,.47,.34,.55,tint(stone,.83))
bake('BrokenArch')
rng.setstate(arch_rng_state)
def deck(x):return .65*x/6-.48*sin(pi*x/6)
for i in range(21):
    x=(i+.5)*6/21;block(x,deck(x)-.09,0,.276,.18,rng.uniform(1.28,1.42),tint(wood,rng.uniform(.8,1.35)))
for side in [-1,1]:
    z=side*.67
    for j in range(5):
        x=1.5*j;beam((x,deck(x)-.26,z),(x+.025,deck(x)+.85,z),.095,.078,wood)
        for k in range(3):beam((x,deck(x)+.61+k*.044,z),(x,deck(x)+.65+k*.044,z),.105,.105,rope)
    for i in range(60):
        def p(k):
            x=k*.1;return (x,deck(x)+.68-.11*abs(sin(pi*x/1.5)),z)
        beam(p(i),p(i+1),.028,.028,rope,6)
bake('Bridge')
for i in range(5):block((i-2)*.18,.41,0,.175,.82,.77,tint(wood,rng.uniform(.85,1.22)))
for z in [-.41,.41]:
    for y in [.08,.74]:block(0,y,z,.95,.14,.1,wood)
    beam((-.39,.12,z),(.39,.71,z),.081,.081,rope,4)
bake('Crate')
for j in range(14):
    a=j*2*pi/14;b=(j+.96)*2*pi/14
    rows=[[(r*cos(t),y,r*sin(t)) for t in (a,b)] for y,r in [(0,.34),(.22,.4),(.55,.42),(.85,.34)]]
    for l,h in zip(rows,rows[1:]):tri(l[0],h[0],l[1],wood);tri(l[1],h[0],h[1],wood)
for y,r in [(.14,.397),(.68,.394),(.84,.35)]:tube([ring(0,y,0,r,r,14),ring(0,y+.06,0,r,r,14)],(.14,.17,.19))
bake('Barrel')
beam((0,0,0),(0,1.3,0),.085,.08,wood);block(0,1,0,1.07,.47,.14,wood)
block(-.03,1,.081,.53,.075,.015,(.97,.83,.54));tri((.17,.84,.095),(.44,1,.095),(.17,1.16,.095),(.97,.83,.54));bake('Sign')
for color,name in [((1,.54,.035),'Sunstone'),((.02,.64,1),'Aether')]:
    tube([ring(0,y,0,r,r,7) for y,r in [(-.32,.005),(-.045,.20),(.015,.21),(.32,.006)]],color);bake(name)
beam((0,0,-.05),(0,0,.05),.22,.22,(.95,.53,.045),20);beam((0,0,.05),(0,0,.064),.16,.16,(1,.72,.13),16);bake('Coin')
bulb(0,.31,0,.34,.32,.28,(.85,.62,.32))
for x in [-.19,.19]:
    bulb(x,.085,.09,.15,.09,.19,(.24,.09,.04));bulb(x*.75,.37,.24,.052,.078,.035,(.036,.024,.03))
tube([ring(0,y,0,r,r*.83,20) for y,r in [(.48,.54),(.54,.56),(.69,.49),(.83,.33),(.9,.03)]],(.85,.054,.031))
for i in range(9):
    a=i*2.4;bulb(.34*cos(a),.748,.28*sin(a),.086,.026,.071,(1,.84,.56),n=6)
bake('Sporeling')
# Folded tapered leaves around a rosette, with contrasting midribs.
for i in range(16):
    a=i*2.39996;length=rng.uniform(.28,.64);h=rng.uniform(.23,.53);w=rng.uniform(.052,.095);c=rng.choice([(.22,.43,.042),(.29,.56,.049),(.45,.65,.058)])
    pts=[]
    for j in range(7):
        t=j/6;span=w*sin(pi*t);x=cos(a)*length*t;z=sin(a)*length*t;y=h*sin(t*2.21)
        pts.append(((x-span*sin(a),y-span*.45,z+span*cos(a)),(x,y+.012,z),(x+span*sin(a),y-span*.45,z-span*cos(a))))
    for l,u in zip(pts,pts[1:]):
        for k in range(2):
            cc=tint(c,1.15 if k else .82);tri(l[k],u[k],l[k+1],cc,'Foliage');tri(l[k+1],u[k],u[k+1],cc,'Foliage')
bake('Rosette')
beam((-.45,0,0),(.45,0,0),.045,.045,rope)
for k in range(10):
    x=(k-5)*.076
    def cloth(t):
        return [(t,-.04,.04*sin(t*18)),(t,-1.26+abs(t)*.9,.07*sin(t*17))]
    a,b=cloth(x),cloth(x+.077);col=(.61,.047,.069) if k not in (0,9) else (.93,.55,.10)
    tri(a[0],b[0],a[1],col);tri(a[1],b[0],b[1],col)
for r,col,z in [(.20,(.92,.71,.30),.09),(.135,(.61,.047,.069),.10),(.065,(.98,.81,.47),.11)]:
    tri((-r,-.50,z),(0,-.50+r*1.4,z),(r,-.50,z),col);tri((-r,-.50,z),(r,-.50,z),(0,-.50-r*1.4,z),col)
bake('Pennant')
