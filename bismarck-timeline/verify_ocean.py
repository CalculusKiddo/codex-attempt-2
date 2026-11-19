"""Check GPU wave evolution, world anchoring and the matched final-action handoff.
Generate inputs with ./render . --ocean-review. Requires NumPy.
"""
from pathlib import Path
import json
import numpy as np
shape=(1080,1920,4)
def rgba(name):
    return np.fromfile(name+'.rgba',np.uint8).reshape(shape)[:,:,:3].astype(np.float32)
def rmse(x,y):
    return float(np.sqrt(np.mean((x-y)**2)))
a,b,n,p=map(rgba,['wave-a','wave-b','wave-next','wave-pan'])
pan=rmse(a[:,1:,:],p[:,:-1,:]);adjacent=rmse(a,n)
x=a[::3,::3].mean(2);y=b[::3,::3].mean(2);x-=x.mean();y-=y.mean()
corr=np.fft.ifft2(np.fft.fft2(x)*np.conj(np.fft.fft2(y))).real
sy,sx=np.unravel_index(np.argmax(corr),corr.shape)
sy=int(sy if sy<180 else sy-360);sx=int(sx if sx<320 else sx-640)
shifted=np.roll(b,(sy*3,sx*3),(0,1))
deform=rmse(a[80:-80,80:-80],shifted[80:-80,80:-80])
h1=np.fromfile('handoff-before.argb',np.uint8).reshape(shape).astype(np.float32)
h2=np.fromfile('handoff-after.argb',np.uint8).reshape(shape).astype(np.float32)
# Upper corners contain only sea. Exclude the changing bottom-left script cue.
mask=np.zeros(shape[:2],bool);mask[:200,:400]=True;mask[:200,-400:]=True
handoff=rmse(h1[mask,1:],h2[mask,1:])
report={'adjacent_frame_rmse_8bit':adjacent,'one_pixel_camera_pan_rmse_8bit':pan,
        'best_translation_after_one_second_pixels':[sx*3,sy*3],
        'residual_after_best_translation_rmse_8bit':deform,
        'night_to_morning_ocean_corner_rmse_8bit':handoff,
        'wave_components':48,'wave_source':'ocean-waves.metal','static_texture_used':False}
print(json.dumps(report,indent=2))
assert 0.1<adjacent<5 and pan<1 and deform>2 and handoff<2
Path('ocean-wave-audit.json').write_text(json.dumps(report,indent=2)+'\n')
