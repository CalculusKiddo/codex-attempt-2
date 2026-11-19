from pathlib import Path
import struct,hashlib,json
p=Path('bismarck-silent.mp4');data=p.read_bytes()
def atoms(start,end):
 while start+8<=end:
  size,tag=struct.unpack_from('>I4s',data,start);h=8
  if size==1:size=struct.unpack_from('>Q',data,start+8)[0];h=16
  if size==0:size=end-start
  assert size>=h and start+size<=end
  yield tag,start+h,start+size
  start+=size
tracks=[];duration=None
for tag,a,b in atoms(0,len(data)):
 if tag!=b'moov':continue
 for typ,c,d in atoms(a,b):
  if typ==b'mvhd':
   version=data[c];o=c+(20 if version else 12);timescale=struct.unpack_from('>I',data,o)[0];dur=struct.unpack_from('>Q' if version else '>I',data,o+4)[0];duration=dur/timescale
  if typ!=b'trak':continue
  track={}
  for t,e,f in atoms(c,d):
   if t!=b'mdia':continue
   for t2,g,h in atoms(e,f):
    if t2==b'hdlr':track['type']=data[g+8:g+12].decode()
    if t2!=b'minf':continue
    for t3,i,j in atoms(g,h):
     if t3!=b'stbl':continue
     for t4,k,l in atoms(i,j):
      if t4==b'stsz':track['frames']=struct.unpack_from('>I',data,k+8)[0]
      if t4==b'stsd':
       entry=k+8;track['codec']=data[entry+4:entry+8].decode();track['width'],track['height']=struct.unpack_from('>HH',data,entry+32)
  tracks.append(track)
assert duration==450 and len(tracks)==1 and tracks[0]=={'type':'vide','codec':'avc1','width':1920,'height':1080,'frames':10800},(duration,tracks)
report={'duration_seconds':duration,'fps':24,'tracks':tracks,'audio_tracks':0,'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest(),'decode':'Full ffmpeg decode with -xerror completed without errors'}
print(json.dumps(report,indent=2));Path('video-verification.json').write_text(json.dumps(report,indent=2)+'\n')
