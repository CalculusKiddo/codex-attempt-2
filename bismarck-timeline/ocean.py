"""Create an original procedural 2D sea texture; no AI or downloaded imagery."""
from pathlib import Path
import numpy as np, struct,zlib
rng=np.random.default_rng(1941);n=2048
x,y=np.meshgrid(np.arange(n,dtype=np.float32)/n,np.arange(n,dtype=np.float32)/n)
z=np.zeros((n,n),np.float32)
for k in range(85):
 f=np.exp(rng.uniform(np.log(12),np.log(900)));angle=rng.normal(-.45,.15);phase=rng.uniform(0,6.283)
 z+=np.sin((x*np.cos(angle)+y*np.sin(angle))*f*6.283+phase)/(f**.68)
gy,gx=np.gradient(z)
normal=np.clip((gx-gy)*190,-1,1)
base=np.array([24,49,59],np.float32)
col=base[None,None,:]+normal[:,:,None]*np.array([2,4,5])
foam=np.clip((z-.20)*3,0,.5)*np.clip(normal+.2,0,1)
col+=foam[:,:,None]*np.array([8,10,12])
col=np.clip(col,0,255).astype(np.uint8)
def chunk(tag,b):return struct.pack('>I',len(b))+tag+b+struct.pack('>I',zlib.crc32(tag+b)&0xffffffff)
raw=b''.join(b'\0'+col[row].tobytes() for row in range(n))
png=b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',n,n,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(raw,8))+chunk(b'IEND',b'')
(Path(__file__).parent/'ocean.png').write_bytes(png)
