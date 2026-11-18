import AppKit
import CoreGraphics
import Foundation

let root=URL(fileURLWithPath:CommandLine.arguments[1])
let W=1920, H=1080, fps=24, duration=300
let ink=NSColor(calibratedRed:0.045,green:0.09,blue:0.115,alpha:1)
let paper=NSColor(calibratedRed:0.89,green:0.90,blue:0.85,alpha:1)
let gold=NSColor(calibratedRed:0.92,green:0.67,blue:0.34,alpha:1)
let red=NSColor(calibratedRed:0.88,green:0.31,blue:0.25,alpha:1)
let blue=NSColor(calibratedRed:0.43,green:0.72,blue:0.81,alpha:1)
let grey=NSColor(calibratedRed:0.39,green:0.44,blue:0.45,alpha:1)
let deck=NSColor(calibratedRed:0.64,green:0.53,blue:0.36,alpha:1)
func pt(_ x:Double,_ y:Double)->CGPoint{CGPoint(x:x,y:y)}
func mix(_ a:Double,_ b:Double,_ q:Double)->Double{a+(b-a)*q}
func ease(_ x:Double)->Double{let q=max(0,min(1,x));return q*q*(3-2*q)}
func txt(_ s:String,_ x:Double,_ y:Double,_ size:Double,_ color:NSColor=paper,_ bold:Bool=false,_ width:Double=1150){
 let style=NSMutableParagraphStyle();style.lineSpacing=3
 let f=NSFont(name:bold ? "AvenirNextCondensed-DemiBold":"AvenirNext-Medium",size:size) ?? NSFont.systemFont(ofSize:size)
 (s as NSString).draw(in:NSRect(x:x,y:y,width:width,height:120),withAttributes:[.font:f,.foregroundColor:color,.paragraphStyle:style])
}
func line(_ c:CGContext,_ p:[CGPoint],_ col:NSColor,_ w:Double=1){guard let a=p.first else{return};c.beginPath();c.move(to:a);for b in p.dropFirst(){c.addLine(to:b)};c.setStrokeColor(col.cgColor);c.setLineWidth(w);c.strokePath()}
func polygon(_ c:CGContext,_ p:[CGPoint],_ col:NSColor){c.beginPath();c.addLines(between:p);c.closePath();c.setFillColor(col.cgColor);c.fillPath()}
func ellipse(_ c:CGContext,_ x:Double,_ y:Double,_ rx:Double,_ ry:Double,_ color:NSColor){c.setFillColor(color.cgColor);c.fillEllipse(in:CGRect(x:x-rx,y:y-ry,width:rx*2,height:ry*2))}
struct V {var x:Double;var y:Double;var z:Double;init(_ x:Double,_ y:Double,_ z:Double){self.x=x;self.y=y;self.z=z}}
struct Face {let v:[V];let c:NSColor}
struct Model {
 var f:[Face]=[]
 var kind=0
 mutating func face(_ v:[V],_ c:NSColor){f.append(Face(v:v,c:c))}
 mutating func prism(_ outline:[CGPoint],_ z:Double,_ h:Double,_ c:NSColor){
  face(outline.map{V($0.x,$0.y,z+h)},c)
  for i in outline.indices {let a=outline[i],b=outline[(i+1)%outline.count];let shade=0.52+Double(i%3)*0.1
   face([V(a.x,a.y,z),V(b.x,b.y,z),V(b.x,b.y,z+h),V(a.x,a.y,z+h)],c.blended(withFraction:1-shade,of:.black)!)}
 }
 mutating func box(_ x:Double,_ y:Double,_ w:Double,_ d:Double,_ z:Double,_ h:Double,_ c:NSColor){prism([pt(x,y),pt(x+w,y),pt(x+w,y+d),pt(x,y+d)],z,h,c)}
 mutating func cylinder(_ x:Double,_ y:Double,_ rx:Double,_ ry:Double,_ z:Double,_ h:Double,_ c:NSColor){let o=(0..<12).map{n in let a=Double(n)*Double.pi/6;return pt(x+cos(a)*rx,y+sin(a)*ry)};prism(o,z,h,c)}
}
func makeShip(_ kind:Int=0,_ turretAngle:Double=0,_ damaged:Bool=false)->Model{
 var m=Model();m.kind=kind
 let factor=kind==1 ? 0.82 : 1.0
 var hull:[CGPoint]=[]
 for side in [-1.0,1.0]{let range=side<0 ? Array(0...32):Array((0...32).reversed());for j in range{let q=Double(j)/32;let x=mix(-125,125,q);let w=18*pow(max(0,sin(q*Double.pi)),0.50);hull.append(pt(x,w*side))}}
 m.prism(hull,0,8,grey);m.prism(hull.map{pt($0.x*0.975,$0.y*0.90)},8,0.8,deck)
 // Planked deck: thin raised strips follow the hull width.
 for x in stride(from:-116.0,through:115,by:4){let q=(x+125)/250;let w=16*pow(max(0,sin(q*Double.pi)),0.5);m.box(x,-w,0.35,w*2,8.85,0.05,NSColor(calibratedWhite:0.20,alpha:1))}
 let structureStart=m.f.count
 m.box(-44,-11,82,22,9,5,grey);m.box(4,-9,25,18,14,8,grey);m.box(8,-7,18,14,22,6,grey)
 m.box(11,-9,12,18,28,2,grey);m.cylinder(17,0,4,4,30,5,grey)
 // Single funnel, aft mast, foremast and horizontal yards.
 m.cylinder(-13,0,7,5,14,17,grey);m.cylinder(-13,0,6,4,31,1.5,NSColor.black)
 m.box(16,-0.5,1,1,34,22,grey);m.box(7,-0.5,20,1,48,0.7,grey)
 m.box(-37,-0.5,1,1,15,26,grey);m.box(-46,-0.5,18,1,33,0.5,grey)
 if kind==2 {for i in structureStart..<m.f.count {let f=m.f[i];m.f[i]=Face(v:f.v.map{V($0.x-65,$0.y,$0.z)},c:f.c)}}
 // Main turrets are drawn independently so they train toward the target.
 if kind==1 || kind==4 {m.cylinder(-44,0,6,4,14,15,grey);m.cylinder(-44,0,5,3,29,1.5,NSColor.black)}
 for side in [-1.0,1.0]{
  for x in [-40.0,-13.0,29.0]{m.cylinder(x,13*side,4,3,9,4,grey);m.box(x-1,13*side,9,0.6,12,0.6,grey)}
  for x in [-50.0,-27.0,3.0,35.0]{m.cylinder(x,11*side,1.7,1.7,15,2,NSColor(calibratedWhite:0.55,alpha:1))}
  for x in [-34.0,-23.0]{m.prism([pt(x-4,7*side),pt(x+4,7*side),pt(x+5,9*side),pt(x-4,10*side)],15,1,paper)}
  // Railings, anchors and capstans.
  m.box(-82,16*side,160,0.25,9,1.5,grey)
 }
 m.cylinder(107,0,1.6,1.6,9,0.6,grey);m.box(-5,-18,1,36,15,0.7,grey)
 if kind==4 {m.f=m.f.map{Face(v:$0.v.map{V($0.x*1.046,$0.y*0.894,$0.z)},c:$0.c)}}
 if kind==1 {m.f=m.f.map{Face(v:$0.v.map{V($0.x*factor,$0.y*0.8,$0.z*0.8)},c:$0.c)}}
 return m
}
let shipModel=makeShip(), cruiserModel=makeShip(1), rodneyModel=makeShip(2), kgvModel=makeShip(3), hoodModel=makeShip(4)
// Original, high-resolution 2D plan sprites; no generated imagery is used.
struct PlanSprite {let image:CGImage;let kind:Int}
func makePlan(_ kind:Int)->PlanSprite {
 let width=4096,height=960
 let ctx=CGContext(data:nil,width:width,height:height,bitsPerComponent:8,bytesPerRow:width*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
 ctx.translateBy(x:2048,y:480);ctx.scaleBy(x:14,y:14)
 let model=makeShip(kind)
 // Select level top faces, keeping the vertical presentation strictly orthographic.
 let faces=model.f.filter{f in let z=f.v[0].z;return f.v.allSatisfy{abs($0.z-z)<0.05}}
 for f in faces.sorted(by:{$0.v[0].z<$1.v[0].z}) {
  let path=f.v.map{pt($0.x,$0.y)}
  ctx.saveGState();ctx.setShadow(offset:CGSize(width:0.45,height:-0.5),blur:0.55,color:NSColor.black.withAlphaComponent(0.5).cgColor)
  polygon(ctx,path,f.c);ctx.restoreGState()
  line(ctx,path+[path[0]],NSColor.black.withAlphaComponent(0.45),0.09)
 }
 // Planks run along the hull, with staggered butt joints and nonuniform timber tones.
 ctx.saveGState();let hull=faces.first!;ctx.beginPath();ctx.addLines(between:hull.v.map{pt($0.x*0.97,$0.y*0.9)});ctx.closePath();ctx.clip()
 for row in -48...48 {
  let y=Double(row)*0.34
  for n in -15...15 {
   let x=Double(n)*9+Double(abs(row)%4)*2.25
   let shade=Double(abs(row*71+n*17)%13)/100
   ctx.setFillColor(NSColor(calibratedRed:0.52+shade,green:0.43+shade,blue:0.29+shade*0.7,alpha:1).cgColor)
   ctx.fill(CGRect(x:x,y:y,width:8.92,height:0.31))
  }
 }
 ctx.restoreGState()
 // Restore raised fittings over the planked deck.
 for f in faces.filter({$0.v[0].z>9.1}).sorted(by:{$0.v[0].z<$1.v[0].z}){
  let path=f.v.map{pt($0.x,$0.y)}
  ctx.saveGState();ctx.setShadow(offset:CGSize(width:0.5,height:-0.6),blur:0.65,color:NSColor.black.withAlphaComponent(0.6).cgColor);polygon(ctx,path,f.c);ctx.restoreGState()
  line(ctx,path+[path[0]],NSColor.black.withAlphaComponent(0.6),0.12)
  if path.count==4 {line(ctx,[path[0],path[1]],paper.withAlphaComponent(0.32),0.12)}
 }
 // Deck hardware, scuttles, vents, cable runs and hatches. All geometry is authored here.
 for side in [-1.0,1.0] {
  for x in stride(from:-98.0,through:98,by:3.1) {
   let q=(x+125)/250;let y=side*17.1*pow(max(0,sin(q*Double.pi)),0.5)
   ellipse(ctx,x,y,0.23,0.23,grey);line(ctx,[pt(x,y),pt(x+1.3,y)],paper.withAlphaComponent(0.6),0.07)
  }
  for x in stride(from:-51.0,through:38,by:5.5) {
   let y=side*9.3;polygon(ctx,[pt(x,y),pt(x+2.1,y),pt(x+2.1,y+side*1.1),pt(x,y+side*1.1)],grey)
   for n in 0..<4{line(ctx,[pt(x+Double(n)*0.5,y),pt(x+Double(n)*0.5,y+side)],NSColor.black.withAlphaComponent(0.6),0.1)}
  }
  for x in [-115.0,-108,92,103,111] {ellipse(ctx,x,side*3.8,0.8,0.8,grey);ellipse(ctx,x,side*3.8,0.4,0.4,NSColor.black)}
  // Anchor chain links follow the forecastle run; no bow-stem anchor is drawn.
  for n in 0..<46 {let x=96+Double(n)*0.32;let y=side*(2.5+Double(n)*0.065);ctx.setStrokeColor(NSColor.darkGray.cgColor);ctx.setLineWidth(0.11);ctx.strokeEllipse(in:CGRect(x:x,y:y,width:0.42,height:0.25))}
  // Secondary-battery gun barrels and roof seams.
  for x in [-40.0,-13,29] {for off in [-0.65,0.65]{line(ctx,[pt(x+off,side*13),pt(x+off,side*19)],NSColor(calibratedWhite:0.56,alpha:1),0.5)};line(ctx,[pt(x-2,side*11),pt(x+2,side*11)],paper.withAlphaComponent(0.3),0.15)}
  for x in [-48.0,-26,3,34] {ellipse(ctx,x,side*11,1.35,1.35,grey);line(ctx,[pt(x-1,side*11),pt(x+2,side*11)],paper,0.2)}
 }
 // Individually drawn roof plates, skylights, ventilation banks, ladders and catwalks.
 for f in faces.filter({$0.v[0].z>12}) {
  let xs=f.v.map{$0.x},ys=f.v.map{$0.y};let x0=xs.min()!,x1=xs.max()!,y0=ys.min()!,y1=ys.max()!
  guard x1-x0>8 && y1-y0>7 else{continue}
  ctx.saveGState();ctx.beginPath();ctx.addLines(between:f.v.map{pt($0.x,$0.y)});ctx.closePath();ctx.clip()
  for y in stride(from:y0,through:y1,by:1.5){line(ctx,[pt(x0,y),pt(x1,y)],paper.withAlphaComponent(0.07),0.08)}
  for x in stride(from:x0+1,through:x1,by:4.3){line(ctx,[pt(x,y0),pt(x,y1)],NSColor.black.withAlphaComponent(0.12),0.1)}
  for n in 0..<Int((x1-x0)/3) {let x=x0+1+Double(n)*3
   if abs(y0)>1 || f.v[0].z<20 {
    for y in [y0+1,y1-2]{ctx.setFillColor(NSColor(calibratedWhite:0.25,alpha:1).cgColor);ctx.fill(CGRect(x:x,y:y,width:1.8,height:0.95));line(ctx,[pt(x,y),pt(x+1.8,y)],paper.withAlphaComponent(0.5),0.09)}
   }
  }
  ctx.restoreGState()
 }
 for x in [-45.0,-35,-24,-2,30] {for side in [-1.0,1.0] {
  let y=side*6.0
  polygon(ctx,[pt(x,y),pt(x+2.6,y),pt(x+2.6,y+side*1.8),pt(x,y+side*1.8)],NSColor(calibratedWhite:0.29,alpha:1))
  for n in 0..<6 {line(ctx,[pt(x+Double(n)*0.42,y),pt(x+Double(n)*0.42,y+side*1.8)],paper.withAlphaComponent(0.45),0.11)}
 }}
 // Lattice crane arms, motor launches and fine longitudinal cabling.
 for side in [-1.0,1.0] {
  for n in 0..<7 {let x = -34+Double(n)*1.6;line(ctx,[pt(x,side*8),pt(x+1.6,side*13)],grey,0.16);line(ctx,[pt(x+1.6,side*8),pt(x,side*13)],grey,0.16)}
  for y in [2.2,3.0]{line(ctx,[pt(-105,y*side),pt(-58,y*side)],NSColor.black.withAlphaComponent(0.3),0.1)}
  for x in [-37.0,16]{for n in 0..<7{let a=Double(n)*Double.pi/3.5;line(ctx,[pt(x,0),pt(x+cos(a)*10,sin(a)*8)],NSColor(calibratedWhite:0.62,alpha:1).withAlphaComponent(0.45),0.06)}}
 }
 // Boat ribs, crane lattice and seaplane catapult detail.
 for side in [-1.0,1.0] {for x in [-34.0,-23]{for n in -3...3{line(ctx,[pt(x+Double(n),side*7.4),pt(x+Double(n),side*9.3)],grey,0.12)}}}
 for x in stride(from:-6.0,through:2,by:0.6){line(ctx,[pt(x,-16),pt(x+0.6,16)],grey,0.12)}
 for a in [-37.0,16] {line(ctx,[pt(a-9,0),pt(a+9,0)],paper.withAlphaComponent(0.7),0.15);line(ctx,[pt(a,-7),pt(a,7)],paper.withAlphaComponent(0.7),0.15)}
 let img=ctx.makeImage()!
 return PlanSprite(image:img,kind:kind)
}
let plans=(0...4).map{makePlan($0)}
var aimWorld:Double?=nil
var currentTime=0.0
func ship(_ c:CGContext,_ model:Model,_ x:Double,_ y:Double,_ scale:Double,_ yaw:Double,_ elevation:Double,_ t:Double,_ wake:Bool=true){
 let kind=model.kind
 c.saveGState();c.translateBy(x:x,y:y);c.rotate(by:yaw);c.scaleBy(x:scale,y:scale)
 if wake {for n in 0..<13{let q=(Double(n)/13+t*0.11).truncatingRemainder(dividingBy:1);let back = -126-q*100
  line(c,[pt(back,-q*15),pt(back+15,0),pt(back,q*15)],paper.withAlphaComponent((1-q)*0.23),0.5)
 }}
 c.setShadow(offset:CGSize(width:1,height:1),blur:1.5,color:NSColor.black.withAlphaComponent(0.4).cgColor)
 c.draw(plans[kind].image,in:CGRect(x:-2048.0/14,y:-480.0/14,width:4096.0/14,height:960.0/14));c.setShadow(offset:.zero,blur:0,color:nil)
 // Dynamic main turrets, independently trained to target bearings.
 let locations:[Double]=kind==2 ? [76,45,12]:kind==3 ? [72,46,-85]:[72,46,-61,-91]
 for (j,tx) in locations.enumerated(){
  let defaultA=(kind==2 || j<2) ? 0.0:Double.pi
  let aim=(aimWorld ?? (yaw+defaultA))-yaw
  let relative=abs(atan2(sin(aim),cos(aim)))
  let canBear = kind==2 && j==2 ? relative>0.61 && relative<2.53 : (j<2 || kind==2) ? relative<2.53 : relative>0.61
  let angle=canBear ? aim:defaultA
  ellipse(c,tx,0,8.2,8.2,grey)
  c.saveGState();c.translateBy(x:tx,y:0);c.rotate(by:angle)
  polygon(c,[pt(-7,-6),pt(5,-6),pt(9,-3.5),pt(9,3.5),pt(5,6),pt(-7,6)],NSColor(calibratedWhite:0.36,alpha:1))
  line(c,[pt(-6,-5.4),pt(4,-5.4),pt(8,-3)],paper.withAlphaComponent(0.5),0.18)
  line(c,[pt(-5,4.7),pt(5,4.7)],NSColor.black.withAlphaComponent(0.5),0.14)
  for h in [-2.0,2.0]{polygon(c,[pt(-4,h-0.7),pt(-2,h-0.7),pt(-2,h+0.7),pt(-4,h+0.7)],grey)}
  let barrels:[Double]=kind==2 ? [-3,0,3]:kind==3 && j != 1 ? [-3,-1,1,3]:[-2.4,2.4]
  for yy in barrels{line(c,[pt(7,yy),pt(26.6,yy)],NSColor.darkGray,1.15);line(c,[pt(8,yy-0.19),pt(26.3,yy-0.19)],NSColor(calibratedWhite:0.67,alpha:1),0.24);ellipse(c,26.6,yy,0.28,0.43,NSColor.black)}
  line(c,[pt(-1,-9),pt(-1,9)],grey,0.65)
  c.restoreGState()
 }
 c.restoreGState()
}
func aircraft(_ c:CGContext,_ x:Double,_ y:Double,_ scale:Double,_ angle:Double,_ t:Double){
 c.saveGState();c.translateBy(x:x,y:y);c.rotate(by:angle);c.scaleBy(x:scale,y:scale)
 ellipse(c,3,3,32,4,NSColor.black.withAlphaComponent(0.13))
 polygon(c,[pt(-34,0),pt(24,-4),pt(38,0),pt(24,4)],grey)
 for yy in [-4.0,4.0]{polygon(c,[pt(-7,yy-39),pt(8,yy-39),pt(12,yy+39),pt(-7,yy+39)],deck);line(c,[pt(0,yy-34),pt(6,yy+34)],paper.withAlphaComponent(0.5),1)}
 polygon(c,[pt(-30,-16),pt(-24,-16),pt(-22,16),pt(-30,16)],grey)
 ellipse(c,8,0,5,3,NSColor.black);line(c,[pt(36,-13),pt(36,13)],paper.withAlphaComponent(0.6+0.3*sin(t*70)),2)
 for side in [-1.0,1.0]{ellipse(c,1,side*29,3.8,3.8,blue);ellipse(c,1,side*29,2.5,2.5,paper);ellipse(c,1,side*29,1.3,1.3,red)}
 c.restoreGState()
}
let seaImage=NSImage(contentsOf:root.appendingPathComponent("ocean.png"))!.cgImage(forProposedRect:nil,context:nil,hints:nil)!
func ocean(_ c:CGContext,_ t:Double,_ storm:Bool=false){
 c.setFillColor(ink.cgColor);c.fill(CGRect(x:0,y:0,width:1280,height:720))
 c.saveGState();let drift=t*1.4;let offset=drift.truncatingRemainder(dividingBy:500)
 c.setAlpha(0.65);c.draw(seaImage,in:CGRect(x:-offset,y:-offset*0.35,width:1900,height:1300));c.restoreGState()
 let colors=[ink.cgColor,NSColor(calibratedRed:0.10,green:0.18,blue:0.20,alpha:1).cgColor] as CFArray
 let g=CGGradient(colorsSpace:CGColorSpaceCreateDeviceRGB(),colors:colors,locations:[0,1])!;c.saveGState();c.setAlpha(0.35);c.drawLinearGradient(g,start:pt(0,0),end:pt(1280,720),options:[]);c.restoreGState()
 for j in 0..<90{let y=Double((j*79)%720);let x=Double((j*137)%1500)-100+sin(t*0.4+Double(j))*15;let l=Double(20+(j*31)%160);line(c,[pt(x,y),pt(x+l,y-5)],paper.withAlphaComponent(storm ? 0.06:0.035),1)}
 if storm {for j in 0..<100{let x=Double((j*113)%1500)-100+(t*160).truncatingRemainder(dividingBy:180);let y=(Double(j*53)+t*430).truncatingRemainder(dividingBy:820)-70;line(c,[pt(x,y),pt(x-18,y+42)],paper.withAlphaComponent(0.10),1)}}
}
func blast(_ c:CGContext,_ x:Double,_ y:Double,_ age:Double,_ size:Double,_ fire:Bool=false){
 guard age>=0 && age<3 else{return}
 let q=age/3
 for n in 0..<20{let a=Double(n)*2.399;let r=sqrt(Double(n)/20)*size*(0.3+q);let dx=cos(a)*r,dy=sin(a)*r*0.7-q*size*0.7
  let col=fire && age<0.7 ? gold:paper
  ellipse(c,x+dx,y+dy,size*0.14*(1+q),size*0.2*(1+q),col.withAlphaComponent((1-q)*0.45))
 }
 if fire && age<0.3 {ellipse(c,x,y,size*0.35,size*0.3,paper.withAlphaComponent(1-age/0.3))}
}
func label(_ c:CGContext,_ name:String,_ x:Double,_ y:Double,_ color:NSColor){
 line(c,[pt(x,y),pt(x+20,y-25),pt(x+140,y-25)],color,1.5);txt(name,x+25,y-52,17,color,true,230)
}
// Fifty six-second shots: concise captions, actions and camera setups.
let captions=[
 "ONE TORPEDO.","AN ENTIRE PURSUIT CHANGES.",
 "BISMARCK","250.5 m LONG","EIGHT 380 mm GUNS","30 KNOTS / TRIAL TOP SPEED ≈ 30.1",
 "18–21 MAY / BREAKOUT","TWO SHIPS. ONE MISSION.","BERGEN / SPOTTED","23 MAY / DENMARK STRAIT","SUFFOLK MAKES CONTACT","NORFOLK JOINS THE SHADOW",
 "24 MAY / 05:52","GERMAN GUNS ANSWER","FIND THE RANGE","06:01 / HOOD IS LOST","PRINCE OF WALES UNDER FIRE","06:09 / BREAK OFF",
 "THE MISSION CHANGES","PRINZ EUGEN SEPARATES","VICTORIOUS LAUNCHES","A HIT. NO STOP.","25 MAY / CONTACT LOST","26 MAY / CATALINA FINDS HER",
 "ARK ROYAL / FORCE H","FIRST STRIKE: WRONG TARGET","SHEFFIELD ESCAPES","REARM. LAUNCH AGAIN.",
 "26 MAY / DUSK","SWORDFISH CLOSE IN","LOW CLOUD. ROUGH SEA.","SPLIT THE ATTACK","TORPEDO AWAY","RUNNING TOWARD THE STERN","IMPACT","THE RUDDERS JAM",
 "POWER REMAINS. CONTROL IS LOST.","NO RELIABLE COURSE TO FRANCE","REPAIR ATTEMPTS FAIL","BRITISH DESTROYERS CLOSE",
 "27 MAY / MORNING","KING GEORGE V + RODNEY","THE GUNS OPEN","BISMARCK RETURNS FIRE","RANGE CLOSES","GUNS FALL SILENT","DORSETSHIRE / TORPEDOES","BISMARCK SINKS",
 "THE HUMAN COST","THE HUNT FOR BISMARCK"
]
struct Actor {let model:Model;let name:String;let x:Double;let y:Double;let yaw:Double;let scale:Double;let tint:NSColor
 func position(_ sim:Double)->CGPoint {pt(x+cos(yaw)*sim*0.023,y+sin(yaw)*sim*0.023)}
}
struct Salvo {let fire:Double;let from:Int;let to:Int;let guns:Int;let hit:Bool;let serial:Int}
func waterSplash(_ c:CGContext,_ x:Double,_ y:Double,_ age:Double,_ speed:Double){
 guard age>=0 && age<8 else{return};let q=age/8
 let r=2+sqrt(q)*12
 c.setStrokeColor(paper.withAlphaComponent((1-q)*0.6).cgColor);c.setLineWidth(1);c.strokeEllipse(in:CGRect(x:x-r,y:y-r,width:r*2,height:r*2))
 for j in 0..<7{let a=Double(j)*2.399;ellipse(c,x+cos(a)*r*0.4,y+sin(a)*r*0.4,r*0.16,r*0.16,paper.withAlphaComponent((1-q)*0.9))}
}
func gunnery(_ c:CGContext,_ sim:Double,_ speed:Double,_ actors:[Actor],_ events:[Salvo],_ flight:Double){
 // Fall of shot is clustered; range errors are shared by a salvo, with individual dispersion.
 for e in events {
  let age=sim-e.fire;guard age>=0 && age<flight+8 else{continue}
  let a=actors[e.from],b=actors[e.to],origin=a.position(e.fire),future=b.position(e.fire+flight)
  let bearing:Double=atan2(Double(future.y-origin.y),Double(future.x-origin.x))
  let dir=pt(cos(bearing),sin(bearing)),normal=pt(-dir.y,dir.x)
  var offsets:[(Double,Double)] = []
  if a.model.kind==2 {
   offsets=e.guns==5 ? [(76,-3),(76,3),(12,-3),(12,3),(45,0)]:[(76,0),(12,0),(45,-3),(45,3)]
  }else if a.model.kind==3 {offsets=a.name=="PRINCE OF WALES" ? [(72,-3),(72,1),(72,3),(46,-2.4),(46,2.4)] : [(72,-3),(72,1),(46,-2.4),(-85,-3),(-85,1)]}
  else if a.model.kind==4 {offsets=[(72,-2.4),(72,2.4),(46,-2.4),(46,2.4)]}
  else {let sign=e.serial%2==0 ? -2.4:2.4;offsets=[(72,sign),(46,sign),(-61,sign),(-91,sign)]}
  for (j,gun) in offsets.prefix(e.guns).enumerated(){
   let relative=abs(atan2(sin(bearing-a.yaw),cos(bearing-a.yaw)))
   if a.model.kind==2 && gun.0==12 && relative<0.61 {continue}
   if a.model.kind != 2 && gun.0<0 && relative<0.61 {continue}
   if gun.0>0 && relative>2.53 {continue}
   let start=pt(origin.x+cos(a.yaw)*gun.0*a.scale+dir.x*26.6*a.scale+normal.x*gun.1*a.scale,origin.y+sin(a.yaw)*gun.0*a.scale+dir.y*26.6*a.scale+normal.y*gun.1*a.scale)
   // Recoil flash lasts one frame at the displayed speed; smoke lingers separately.
   if age<max(0.12,speed/24){ellipse(c,start.x,start.y,4,4,gold.withAlphaComponent(0.8));ellipse(c,start.x,start.y,1.8,1.8,paper)}
   if age<10 {let q=age/10;ellipse(c,start.x+q*12,start.y-q*8,3+q*10,3+q*7,paper.withAlphaComponent((1-q)*0.18))}
   let rangeError=Double((e.serial*7)%5-2)*4.0
   let spread=sin(Double(e.serial*23+j*11))*3.5
   var end=pt(future.x+dir.x*(rangeError+spread)+normal.x*sin(Double(j*7+e.serial))*3,future.y+dir.y*(rangeError+spread)+normal.y*sin(Double(j*7+e.serial))*3)
   if e.hit && j==0 {end=future}
   let q=min(1,age/flight)
   if age<flight {let pos=pt(mix(start.x,end.x,q),mix(start.y,end.y,q));ellipse(c,pos.x,pos.y,0.8,0.8,paper.withAlphaComponent(0.75))}
   else if e.hit && j==0 {blast(c,end.x,end.y,(age-flight)/speed,45,true)}
   else {waterSplash(c,end.x,end.y,age-flight,speed)}
  }
 }
}
func denmark(_ c:CGContext,_ t:Double,_ shot:Int,_ u:Double){
 let sim=(t-72)*30
 let actors=[Actor(model:shipModel,name:"BISMARCK",x:610,y:285,yaw:2.45,scale:0.90,tint:red),Actor(model:cruiserModel,name:"PRINZ EUGEN",x:390,y:225,yaw:2.45,scale:0.65,tint:red),Actor(model:hoodModel,name:"HOOD",x:880,y:425,yaw:-2.35,scale:0.90,tint:blue),Actor(model:kgvModel,name:"PRINCE OF WALES",x:1060,y:465,yaw:-2.35,scale:0.82,tint:blue)]
 for (i,a) in actors.enumerated(){let p=a.position(sim);let target=actors[i<2 ? 2:0].position(sim)
  aimWorld=atan2(target.y-p.y,target.x-p.x)
  if i==2 && sim>540 {c.saveGState();c.setAlpha(max(0,1-(sim-540)/120));ship(c,a.model,p.x,p.y,a.scale,a.yaw,1.57,t);c.restoreGState();blast(c,p.x,p.y,(sim-540)/30,85,true)}
  else {ship(c,a.model,p.x,p.y,a.scale,a.yaw,1.57,t);label(c,a.name,p.x,p.y-18,a.tint)}
 }
 aimWorld=nil
 var events:[Salvo]=[]
 for (n,fire) in [180.0,235,290,345,400,455,508,580,650,720,800,880,960].enumerated(){events.append(Salvo(fire:fire,from:0,to:fire<540 ? 2:3,guns:4,hit:fire==508,serial:n))}
 for (n,fire) in stride(from:0.0,through:480,by:48).enumerated(){events.append(Salvo(fire:fire,from:2,to:1,guns:4,hit:false,serial:n+20))}
 for (n,fire) in stride(from:30.0,through:970,by:55).enumerated(){events.append(Salvo(fire:fire,from:3,to:0,guns:5,hit:n==3,serial:n+40))}
 gunnery(c,sim,30,actors,events,32)
 let seconds=5*3600+52*60+Int(sim)
 txt(String(format:"%02d:%02d:%02d",seconds/3600,(seconds/60)%60,seconds%60),50,122,24,paper,true)
 txt("24 MAY / TIME ×30 / SYMBOLS ENLARGED",50,158,12,paper.withAlphaComponent(0.65))
 if shot==14 {txt("≈20 km / ≈32 s SHELL FLIGHT",55,540,19,gold,true)}
}
func finalBattle(_ c:CGContext,_ t:Double,_ shot:Int,_ u:Double){
 // Selected historical moments, not an asserted shot-for-shot record.
 let starts=[0.0,180,480,900,1380,2640,5580,6720]
 let real=starts[shot-40]+(t-Double(shot*6))*10
 let sim=real.truncatingRemainder(dividingBy:180)+300
 let actors=[Actor(model:shipModel,name:"BISMARCK",x:850,y:360,yaw:2.5,scale:0.85,tint:red),Actor(model:rodneyModel,name:"RODNEY",x:330,y:240,yaw:0.25,scale:0.84,tint:blue),Actor(model:kgvModel,name:"KING GEORGE V",x:430,y:490,yaw:-0.5,scale:0.84,tint:blue)]
 for (i,a) in actors.enumerated(){let p=a.position(sim);let target=actors[i==0 ? 1:0].position(sim);aimWorld=atan2(target.y-p.y,target.x-p.x)
  c.saveGState();if shot==47 {c.setAlpha(max(0,1-u))};ship(c,a.model,p.x,p.y,a.scale,a.yaw,1.57,t);c.restoreGState();label(c,a.name,p.x,p.y-30,a.tint)
 }
 aimWorld=nil
 var events:[Salvo]=[]
 if shot<46 {for (j,fire) in stride(from:0.0,through:600,by:20).enumerated(){events.append(Salvo(fire:fire,from:1,to:0,guns:j%2==0 ? 5:4,hit:j%9==0,serial:j))}
 for (j,fire) in stride(from:10.0,through:600,by:22).enumerated(){events.append(Salvo(fire:fire,from:2,to:0,guns:5,hit:j%11==0,serial:j+30))}
 if shot<45 {for (j,fire) in stride(from:6.0,through:600,by:48).enumerated(){events.append(Salvo(fire:fire,from:0,to:1,guns:4,hit:false,serial:j+60))}}
 gunnery(c,sim,10,actors,events,shot<44 ? 22.4:11)
 }
 if shot==46 {let p=actors[0].position(sim);let q=u;line(c,[pt(mix(300,p.x,q),mix(450,p.y,q)),pt(mix(330,p.x,q),mix(450,p.y,q))],paper.withAlphaComponent(0.55),1.6)}
 if shot==47 {let p=actors[0].position(sim);for j in 0..<5 {waterSplash(c,p.x+Double(j)*12,p.y,u*8,1)}}
 let secs=8*3600+47*60+Int(real)
 txt(String(format:"%02d:%02d:%02d",secs/3600,(secs/60)%60,secs%60),50,122,24,paper,true)
 txt("27 MAY / SELECTED MOMENTS ×10 / SYMBOLS ENLARGED",50,158,12,paper.withAlphaComponent(0.65))
}

let coastlineJSON=(try! JSONSerialization.jsonObject(with:Data(contentsOf:root.appendingPathComponent("land.geojson")))) as! [String:Any]
func geo(_ lon:Double,_ lat:Double)->CGPoint {pt(640+(lon+15)*18,360-(lat-57)*18)}
func map(_ c:CGContext,_ shot:Int,_ u:Double,_ t:Double){
 c.saveGState();c.clip(to:CGRect(x:0,y:105,width:1280,height:485))
 for feature in coastlineJSON["features"] as! [[String:Any]] {
  let g=feature["geometry"] as! [String:Any]
  var polys:[[[[Double]]]]=[]
  if g["type"] as! String == "Polygon" {polys=[g["coordinates"] as! [[[Double]]]]}
  else {polys=g["coordinates"] as! [[[[Double]]]]}
  for rings in polys {for ring in rings.prefix(1){let points=ring.map{geo($0[0],$0[1])};polygon(c,points,NSColor(calibratedRed:0.22,green:0.26,blue:0.23,alpha:1));line(c,points,paper.withAlphaComponent(0.22),0.9)}}
 }
 for lat in stride(from:45.0,through:75,by:5){line(c,[geo(-60,lat),geo(30,lat)],paper.withAlphaComponent(0.08),0.7)}
 for lon in stride(from:-60.0,through:30,by:10){line(c,[geo(lon,40),geo(lon,80)],paper.withAlphaComponent(0.08),0.7)}
 c.restoreGState()
 for (name,lon,lat) in [("GREENLAND",-44.0,70.0),("ICELAND",-21.5,66.0),("BRITAIN",-5.0,55.0),("NORWAY",8.0,65.0),("BREST",-6.0,48.4)] {let p=geo(lon,lat);txt(name,p.x,p.y,14,paper.withAlphaComponent(0.55),true,180)}
 let route=[geo(18.5,54.5),geo(12,54.6),geo(10.8,55.3),geo(10.4,57.7),geo(5.3,60.3),geo(-1,67),geo(-20,67),geo(-32,63),geo(-37,55),geo(-22,48),geo(-16.2,48.2)]
 line(c,route,paper.withAlphaComponent(0.15),2)
 let beginnings:[Double]=shot<12 ? [0,1.5,4,5.5,6.7,7] : [7.2,7.5,7.7,8,8.3,9.1]
 let durations:[Double]=shot<12 ? [1.5,1.5,1,1.2,0.3,0.2] : [0.3,0.2,0.3,0.3,0.2,0.6]
 let ri=shot<12 ? shot-6:shot-18
 let prog=beginnings[ri]+u*durations[ri]
 let seg=min(9,max(0,Int(prog)));let q=prog-Double(seg)
 let p=pt(mix(route[seg].x,route[seg+1].x,q),mix(route[seg].y,route[seg+1].y,q))
 line(c,Array(route.prefix(seg+1))+[p],red,2.5)
 ship(c,shipModel,p.x,p.y,0.39,atan2(route[seg+1].y-route[seg].y,route[seg+1].x-route[seg].x),1.45,t)
 label(c,"BISMARCK",p.x,p.y,red)
 if shot<9 {ship(c,cruiserModel,p.x-72,p.y+40,0.3,-2.5,1.45,t);label(c,"PRINZ EUGEN",p.x-72,p.y+40,paper)}
 if [10,11,18,19].contains(shot){ship(c,cruiserModel,p.x-170,p.y-70,0.26,0.5,1.45,t);label(c,shot==11 ? "NORFOLK":"SUFFOLK",p.x-170,p.y-70,blue)}
 if shot==22 {let r=30+u*140;c.setStrokeColor(gold.withAlphaComponent(1-u).cgColor);c.setLineWidth(2);c.strokeEllipse(in:CGRect(x:p.x-r,y:p.y-r,width:2*r,height:2*r));txt("CONTACT LOST",470,340,44,gold,true)}
 if shot==23 {aircraft(c,p.x-180+u*320,p.y-100,0.6,0,t);line(c,[pt(p.x-100+u*220,p.y-80),p],gold,1)}
}
func render(_ t:Double,_ c:CGContext){
 let shot=min(49,Int(t/6)), local=t-Double(shot*6),u=local/6
 c.saveGState();c.translateBy(x:0,y:Double(H));c.scaleBy(x:1.5,y:-1.5);NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=NSGraphicsContext(cgContext:c,flipped:true)
 ocean(c,t,shot>=28 && shot<40)
 let move=ease(local/0.9)
 c.saveGState()
 // Quick initial push, then a continuous tracking move. Captions remain locked to screen.
 let zoom=mix(1.30,1,move)+u*0.08
 c.translateBy(x:640,y:350);c.scaleBy(x:zoom,y:zoom);c.translateBy(x:-640+mix(70,0,move)-u*20,y:-350)
 if shot<2 {
  ship(c,shipModel,710,410,3.1+u*0.4,-0.35+u*0.3,0.7,t)
  line(c,[pt(100,530),pt(300+u*240,470)],paper.withAlphaComponent(0.6),3)
  if shot==1 {blast(c,350,430,local-1,130,true)}
 } else if shot<6 {
  let elev=shot==3 ? mix(1.5,1.25,u):mix(0.55,0.9,u)
  let yaw=shot==4 ? -0.1+u*0.65 : -0.3+u*0.4
  ship(c,shipModel,650,420,3.3+u*0.25,yaw,elev,t,false)
  if shot==3 {line(c,[pt(225,530),pt(1065,530)],gold,1.5);for x in [225.0,1065.0]{line(c,[pt(x,520),pt(x,540)],gold,1.5)};txt("OVERALL LENGTH",520,542,13,gold,true)}
  if shot==4 {for x in [380.0,440.0,790.0,880.0]{ellipse(c,x,400,5,5,gold)};txt("4 TWIN TURRETS",490,540,16,gold,true)}
  if shot==5 {txt("36 m",70,240,52,gold,true);txt("BEAM",72,300,14,paper);txt("320 mm",980,240,52,gold,true);txt("MAIN ARMOUR BELT",980,300,14,paper);txt("150,170 hp / MAXIMUM OBTAINED",440,535,17,paper,true)}
 } else if shot<12 || (shot>=18 && shot<24){
  map(c,shot,u,t)
 } else if shot<18 {
  denmark(c,t,shot,u)
 } else if shot<28 {
  // A distinct carrier silhouette and aircraft launch deck.
  c.saveGState();c.translateBy(x:650-u*70,y:385);c.rotate(by:-0.14+u*0.08)
  polygon(c,[pt(-420,-65),pt(420,-65),pt(440,65),pt(-420,65)],grey)
  line(c,[pt(-410,65),pt(440,65)],paper.withAlphaComponent(0.5),1)
  for j in -5...5{line(c,[pt(Double(j)*70,-60),pt(Double(j)*70,60)],paper.withAlphaComponent(0.15),1)}
  line(c,[pt(-400,0),pt(400,0)],paper.withAlphaComponent(0.6),2)
  polygon(c,[pt(-40,45),pt(80,45),pt(80,67),pt(-40,67)],grey)
  for x in stride(from:-35.0,through:75,by:6){line(c,[pt(x,48),pt(x,62)],paper.withAlphaComponent(0.3),1)}
  for n in 0..<6 {aircraft(c,-310+Double(n)*80,-23,0.4,0,t)}
  c.restoreGState()
  aircraft(c,500+u*650,420-u*140,0.8,0,t)
  label(c,shot==25 || shot==26 ? "HMS SHEFFIELD":"HMS ARK ROYAL",120,520,blue)
  if shot==25 || shot==26 {txt("MISIDENTIFIED TARGET",770,225,23,gold,true);ship(c,cruiserModel,920,470,1.1,-0.4,1.1,t)}
 } else if shot<36 {
  let attack=shot-28
  if attack<4 {
   ship(c,shipModel,950-u*60,335,1.1,-0.4,1.2,t)
   for n in 0..<3 {let x=80+Double(n)*110+u*440,y=390+Double(n)*65-u*90;aircraft(c,x,y,1.1-Double(n)*0.18,-0.23,t)}
   if attack>=2 {for n in 0..<8 {let q=(local+Double(n)*0.31).truncatingRemainder(dividingBy:2);blast(c,340+Double((n*97)%650),230+Double((n*83)%250),q,20,false)}}
  } else if attack==4 {
   aircraft(c,610+u*320,285-u*20,2.4,-0.05,t)
   let tx=620+u*180,ty=320+u*u*180
   line(c,[pt(tx-30,ty),pt(tx+30,ty)],paper,7);line(c,[pt(tx-45,ty),pt(tx-100,ty+15)],paper.withAlphaComponent(0.35),2)
  } else if attack==5 {
   ship(c,shipModel,930,360,1.9,1.0,1.45,t)
   let x=mix(90,790,u),y=mix(550,460,u)
   line(c,[pt(x-140,y+20),pt(x,y)],paper.withAlphaComponent(0.7),2);line(c,[pt(x-20,y+3),pt(x+15,y-2)],paper,6)
   txt("ILLUSTRATIVE TORPEDO PATH",65,230,13,gold,true)
  } else {
   ship(c,shipModel,730,425,3.6,-0.25+u*0.4,0.65,t)
   blast(c,310,450,local-0.8,140,true)
   if attack==7 {ellipse(c,300,450,65,20,gold.withAlphaComponent(0.25));label(c,"STEERING HIT",300,450,gold)}
  }
 } else if shot<40 {
  if shot<39 {
   // Cutaway stern: two rudders rotate away from the centerline.
   c.saveGState();c.translateBy(x:660,y:350);c.rotate(by:-0.15+u*0.2)
   polygon(c,[pt(-340,-85),pt(330,-40),pt(370,40),pt(-340,85)],grey.withAlphaComponent(0.6))
   for yy in [-42.0,42.0]{
    ellipse(c,-185,yy,24,24,deck)
    c.saveGState();c.translateBy(x:-265,y:yy);c.rotate(by:0.65)
    polygon(c,[pt(-45,-6),pt(40,-6),pt(40,6),pt(-45,6)],red);c.restoreGState()
   }
   line(c,[pt(-400,0),pt(400,0)],paper.withAlphaComponent(0.3),1)
   c.restoreGState()
   txt("STEERING DAMAGE / PLAN DIAGRAM",400,525,16,gold,true)
  } else {
   ship(c,shipModel,700,360,1.5,0.3+u*0.3,1.45,t)
   for n in 0..<4{let a=Double(n)*1.4+u*0.3;let x=700+cos(a)*330,y=360+sin(a)*180;ship(c,cruiserModel,x,y,0.3,a+Double.pi,1.45,t);line(c,[pt(x,y),pt(mix(x,700,u),mix(y,360,u))],blue.withAlphaComponent(0.3),1)}
  }
 } else if shot<48 {
  finalBattle(c,t,shot,u)
 } else {
  if shot==48 {ship(c,shipModel,650,390,2.4,-0.1,1.4,t,false);c.setFillColor(ink.withAlphaComponent(0.5).cgColor);c.fill(CGRect(x:0,y:130,width:1280,height:460));txt("2,000+ DEAD",375,270,72,paper,true);txt("A LITTLE OVER 100 SURVIVORS",375,355,26,paper)}
  else {txt("OPERATION",75,210,28,gold,true);txt("RHEINÜBUNG",70,245,100,paper,true);txt("18–27 MAY 1941",75,365,25,paper);txt("Original animation • sources and reference in README",75,485,17,paper.withAlphaComponent(0.6))}
 }
 c.restoreGState()
 // Restrained screen-space typography keeps the action dominant.
 c.setFillColor(ink.withAlphaComponent(0.88).cgColor);c.fill(CGRect(x:0,y:0,width:1280,height:100))
 txt("RHEINÜBUNG",45,25,20,gold,true)
 let chapter=shot<2 ? "COLD OPEN / 26 MAY":shot<6 ? "THE SHIP":shot<12 ? "BREAKOUT":shot<18 ? "DENMARK STRAIT":shot<24 ? "THE CHASE":shot<28 ? "FORCE H":shot<36 ? "THE STRIKE":shot<40 ? "STEERING LOST":shot<48 ? "FINAL ENGAGEMENT":"AFTERMATH"
 txt(chapter,910,31,14,paper.withAlphaComponent(0.7),true,330)
 if shot<49 {
  let sz=shot==5 ? 32.0:shot==36 ? 35.0:42.0
  c.setFillColor(ink.withAlphaComponent(0.91).cgColor);c.fill(CGRect(x:0,y:600,width:1280,height:120))
  c.setFillColor(gold.cgColor);c.fill(CGRect(x:45,y:624,width:4,height:47))
  txt(captions[shot],65,622,sz,paper,true)
  txt("ILLUSTRATIVE RECONSTRUCTION • ORIGINAL 2D PLAN ART",65,683,10,paper.withAlphaComponent(0.4))
 }
 let progress=t/300;line(c,[pt(0,718),pt(1280*progress,718)],gold,3)
 // Directional whip transitions, with no long black dissolves.
 if local<0.22 && shot>0 {let q=1-local/0.22;c.setFillColor(ink.withAlphaComponent(q*0.8).cgColor);c.fill(CGRect(x:-1280*(1-q),y:0,width:1280*q,height:720))}
 if shot==49 && local>4 {c.setFillColor(NSColor.black.withAlphaComponent((local-4)/2).cgColor);c.fill(CGRect(x:0,y:0,width:1280,height:720))}
 NSGraphicsContext.restoreGraphicsState();c.restoreGState()
}
let pixels=UnsafeMutableRawPointer.allocate(byteCount:W*H*4,alignment:64)
let context=CGContext(data:pixels,width:W,height:H,bitsPerComponent:8,bytesPerRow:W*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.noneSkipFirst.rawValue)!
if CommandLine.arguments.contains("--stills"){
 for t in [17.0,21,29,51,81,93,147,175,195,207,221,255,285,297]{try autoreleasepool{render(t,context);let rep=NSBitmapImageRep(cgImage:context.makeImage()!);try rep.representation(using:.png,properties:[:])!.write(to:root.appendingPathComponent("shot-\(Int(t)).png"))}}
}else{
 let ffmpeg=CommandLine.arguments[2]
 let patch=CommandLine.arguments.contains("--patch")
 let firstFrame=patch ? 240*fps:0
 let lastFrame=patch ? 288*fps:duration*fps
 let process=Process();process.executableURL=URL(fileURLWithPath:ffmpeg)
 process.arguments=["-y","-v","error","-f","rawvideo","-pixel_format","argb","-video_size","1920x1080","-framerate","24","-i","pipe:0","-an","-c:v","libx264","-crf","17","-preset","fast","-pix_fmt","yuv420p","-movflags","+faststart",root.appendingPathComponent(patch ? "bismarck-patch.mp4":"bismarck-silent.mp4").path]
 let pipe=Pipe();process.standardInput=pipe;try process.run()
 for frame in firstFrame..<lastFrame{autoreleasepool{render(Double(frame)/Double(fps),context);pipe.fileHandleForWriting.write(Data(bytesNoCopy:pixels,count:W*H*4,deallocator:.none))};if frame % 720==0 {print("Rendered \(frame/fps)s");fflush(stdout)}}
 try pipe.fileHandleForWriting.close();process.waitUntilExit();precondition(process.terminationStatus==0);print("VIDEO COMPLETE")
}
pixels.deallocate()
