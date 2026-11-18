"""Generate an original score and effects; mux the five-minute film with FFmpeg."""
from pathlib import Path
import subprocess, wave
import numpy as np
import imageio_ffmpeg
root=Path(__file__).parent
rate=32000; duration=300
rng=np.random.default_rng(1941)
audio=np.zeros((rate*duration,2),np.float32)
def add(start,sound,gain=1,pan=0):
    start=int(start*rate)
    if start<0:return
    n=min(len(sound),len(audio)-start)
    if n<=0:return
    audio[start:start+n,0]+=sound[:n]*gain*np.sqrt((1-pan)/2)
    audio[start:start+n,1]+=sound[:n]*gain*np.sqrt((1+pan)/2)
def timeline(seconds):return np.arange(int(rate*seconds),dtype=np.float32)/rate
def boom(start,gain=.4):
    t=timeline(1.8);low=np.sin(2*np.pi*(48*t+25*(1-np.exp(-9*t))/9))*np.exp(-3.3*t)
    noise=rng.standard_normal(len(t)).astype(np.float32)
    noise=np.convolve(noise,np.ones(35)/35,mode='same')*np.exp(-5*t)
    add(start,(low*.65+noise*.65)*np.minimum(t*80,1),gain)
def whoosh(start,gain=.12):
    t=timeline(.65);n=rng.standard_normal(len(t)).astype(np.float32)
    n=np.convolve(n,np.ones(9)/9,mode='same');env=np.sin(np.pi*t/.65)**2
    add(start,n*env,gain,-.65);add(start+.07,n*env,gain,.65)
# A restrained D-minor ostinato. Intensity rises for the strike and final battle.
beat=60/116
for n,start in enumerate(np.arange(0,288,beat)):
    intensity=.45 if start<36 else .65 if start<168 else 1
    if 216<=start<240:intensity=.5
    if n%2==0:boom(start,.13*intensity)
    t=timeline(.38)
    note=[73.416,73.416,87.307,65.406][int(start/12)%4]*(2 if n%4==3 else 1)
    tone=(np.sin(2*np.pi*note*t)+.24*np.sin(2*np.pi*note*2*t)+.1*np.sin(2*np.pi*note*4*t))
    env=np.minimum(1,t/.015)*np.exp(-11*t)
    add(start,tone*env,.105*intensity,(-.25 if n%2==0 else .25))
    if n%2:
        hiss=rng.standard_normal(len(t)).astype(np.float32)*np.exp(-45*t)
        add(start,hiss,.018*intensity,.4)
# Slow, low sustained harmony and sea-like noise, changing every twelve seconds.
for start in range(0,300,12):
    t=timeline(min(12,300-start));f=[73.416,65.406,58.270,69.296][start//12%4]
    env=np.minimum(1,t/1.5)*np.minimum(1,(12-t)/1.5)
    tone=np.sin(2*np.pi*f*t)+.4*np.sin(2*np.pi*f*1.4983*t)+.2*np.sin(2*np.pi*f*2*t)
    add(start,tone*env,.035 if start<288 else .025,-.2)
    add(start,tone*env,.025,.3)
# Each shot cut gets a brief movement accent; historical moments get designed impacts.
for shot in range(1,48):whoosh(shot*6-.18,.15 if shot in [12,15,28,32,34,40,47] else .065)
for shot in [1,34,35,47]:boom(shot*6+.8,.4)
boom(90,.5) # Hood event, 06:01 in the compressed chronology.
# Fire-group accents follow the authored salvo schedule, not a machine-gun rhythm.
for real in [180,235,290,345,400,455,508,580,650,720,800,880,960]:
    boom(72+real/30,.23)
for real in range(0,481,48):boom(72+real/30,.17)
for real in range(30,971,55):boom(72+real/30,.17)
for shot in range(40,46):
    for off in [.4,2.4,4.4]:boom(shot*6+off,.24)
# Engine pass during launch and torpedo approach.
for start in [162,174,180,186,192,198]:
    t=timeline(5);f=72+12*np.sin(t*.5)
    phase=2*np.pi*np.cumsum(f)/rate
    engine=(np.sin(phase)+.3*np.sin(phase*3))*np.sin(np.pi*t/5)**2
    add(start,engine,.065,-.4);add(start+.05,engine,.04,.4)
# Measured dynamics; gentle onset and a quiet final memorial/title.
t=np.arange(len(audio))/rate
fade=np.minimum(1,t/1.5)*np.minimum(1,(duration-t)/3)
audio*=fade[:,None]
audio=np.tanh(audio*1.3)*.82
with wave.open(str(root/'soundtrack.wav'),'wb') as f:
    f.setnchannels(2);f.setsampwidth(2);f.setframerate(rate);f.writeframes((audio*32767).astype('<i2').tobytes())
ffmpeg=imageio_ffmpeg.get_ffmpeg_exe()
subprocess.run([ffmpeg,'-y','-v','error','-i',str(root/('bismarck-picture.mp4' if (root/'bismarck-picture.mp4').exists() else 'bismarck-silent.mp4')),'-i',str(root/'soundtrack.wav'),'-map','0:v:0','-map','1:a:0','-c:v','copy','-c:a','aac','-b:a','128k','-t','300','-movflags','+faststart',str(root/'bismarck-timeline.mp4')],check=True)
print('AUDIO + FINAL MP4 COMPLETE')
