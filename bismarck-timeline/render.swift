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
 noteShipBody(pt(x,y),scale,yaw)
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
 c.setFillColor(ink.cgColor);c.fill(CGRect(x:-4096,y:-4096,width:8192,height:8192))
 c.saveGState();let drift=t*1.4;let offset=drift.truncatingRemainder(dividingBy:500)
 c.setAlpha(0.65);for ix in -2...2 {for iy in -2...2 {c.draw(seaImage,in:CGRect(x:Double(ix)*1536-offset,y:Double(iy)*1536-offset*0.35,width:1536,height:1536))}};c.restoreGState()
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
func label(_ c:CGContext,_ name:String,_ x:Double,_ y:Double,_ color:NSColor){annotations.append(Annotation(text:name,anchor:screen(pt(x,y)),color:color))}
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
   let rangeError=Double((e.serial*7)%5-2)*35.0
   let safetySide=e.serial%2==0 ? 34.0:-34.0
   let offHull=pt(-sin(b.yaw)*safetySide,cos(b.yaw)*safetySide)
   let spread=sin(Double(e.serial*23+j*11))*3.5
   var end=pt(future.x+offHull.x+dir.x*(rangeError+spread)+normal.x*sin(Double(j*7+e.serial))*3,future.y+offHull.y+dir.y*(rangeError+spread)+normal.y*sin(Double(j*7+e.serial))*3)
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
  let track:(Double)->Pose={r in Pose(p:a.position(r*30),yaw:a.yaw)}
  if !(i==2 && sim>540) {wake(c,track,sim/30,a.scale)}
  if i==2 && sim>540 {c.saveGState();c.setAlpha(max(0,1-(sim-540)/120));ship(c,a.model,p.x,p.y,a.scale,a.yaw,1.57,t,false);c.restoreGState();blast(c,p.x,p.y,(sim-540)/30,85,true)}
  else {ship(c,a.model,p.x,p.y,a.scale,a.yaw,1.57,t,false);label(c,a.name,p.x,p.y-18,a.tint)}
 }
 aimWorld=nil
 var events:[Salvo]=[]
 for (n,fire) in [180.0,235,290,345,400,455,508,580,650,720,800,880,960].enumerated(){events.append(Salvo(fire:fire,from:0,to:fire<540 ? 2:3,guns:4,hit:fire==508,serial:n))}
 for (n,fire) in stride(from:0.0,through:480,by:48).enumerated(){events.append(Salvo(fire:fire,from:2,to:1,guns:4,hit:false,serial:n+20))}
 for (n,fire) in stride(from:30.0,through:970,by:55).enumerated(){events.append(Salvo(fire:fire,from:3,to:0,guns:5,hit:n==3,serial:n+40))}
 gunnery(c,sim,30,actors,events,32)

}
func finalBattle(_ c:CGContext,_ t:Double,_ shot:Int,_ u:Double){
 // Selected historical moments, not an asserted shot-for-shot record.
 let sim=(t-240)*10+300
 let actors=[Actor(model:shipModel,name:"BISMARCK",x:850,y:360,yaw:2.5,scale:0.85,tint:red),Actor(model:rodneyModel,name:"RODNEY",x:330,y:240,yaw:0.25,scale:0.84,tint:blue),Actor(model:kgvModel,name:"KING GEORGE V",x:430,y:490,yaw:-0.5,scale:0.84,tint:blue)]
 for (i,a) in actors.enumerated(){let p=a.position(sim);let target=actors[i==0 ? 1:0].position(sim);aimWorld=atan2(target.y-p.y,target.x-p.x)
  let track:(Double)->Pose={r in Pose(p:a.position(r*10),yaw:a.yaw)}
  if shot<47 {wake(c,track,sim/10,a.scale)}
  c.saveGState();if shot==47 {c.setAlpha(max(0,1-(t-282)/6))};ship(c,a.model,p.x,p.y,a.scale,a.yaw,1.57,t,false);c.restoreGState();label(c,a.name,p.x,p.y+(i==1 ? 80:-30),a.tint)
 }
 aimWorld=nil
 var events:[Salvo]=[]
 if shot<46 {for (j,fire) in stride(from:0.0,through:900,by:20).enumerated(){events.append(Salvo(fire:fire,from:1,to:0,guns:j%2==0 ? 5:4,hit:j%9==0,serial:j))}
 for (j,fire) in stride(from:10.0,through:900,by:22).enumerated(){events.append(Salvo(fire:fire,from:2,to:0,guns:5,hit:j%11==0,serial:j+30))}
 if shot<45 {for (j,fire) in stride(from:6.0,through:900,by:48).enumerated(){events.append(Salvo(fire:fire,from:0,to:1,guns:4,hit:false,serial:j+60))}}
 gunnery(c,sim,10,actors,events,shot<44 ? 22.4:11)
 }
 if shot==46 {let p=actors[0].position(sim);let q=u;line(c,[pt(mix(300,p.x,q),mix(450,p.y,q)),pt(mix(330,p.x,q),mix(450,p.y,q))],paper.withAlphaComponent(0.55),1.6)}
 if shot==47 {let p=actors[0].position(sim);for j in 0..<5 {waterSplash(c,p.x+Double(j)*12,p.y,u*8,1)}}

}

// Motion and presentation are separate: the camera cannot change a vessel's course.
struct Pose {let p:CGPoint;let yaw:Double}
func movingPose(_ position:(Double)->CGPoint,_ t:Double)->Pose {
 let p=position(t),a=position(t-0.0001),b=position(t+0.0001)
 return Pose(p:p,yaw:atan2(Double(b.y-a.y),Double(b.x-a.x)))
}
func forward(_ start:CGPoint,_ heading:Double,_ speed:Double,_ t:Double)->Pose {
 Pose(p:pt(start.x+cos(heading)*speed*t,start.y+sin(heading)*speed*t),yaw:heading)
}
func curved(_ center:CGPoint,_ radius:Double,_ startAngle:Double,_ speed:Double,_ t:Double)->Pose {
 let a=startAngle+t*speed/radius
 return Pose(p:pt(center.x+radius*cos(a),center.y+radius*sin(a)),yaw:a+Double.pi/2)
}
func bezier(_ a:CGPoint,_ b:CGPoint,_ c:CGPoint,_ d:CGPoint,_ u:Double)->CGPoint {
 let v=1-u
 return pt(v*v*v*a.x+3*v*v*u*b.x+3*v*u*u*c.x+u*u*u*d.x,v*v*v*a.y+3*v*v*u*b.y+3*v*u*u*c.y+u*u*u*d.y)
}
func smoothRoute(_ points:[CGPoint],_ progress:Double)->CGPoint {
 let seg=max(0,min(points.count-2,Int(floor(progress)))),q=progress-Double(seg)
 let a=points[seg],b=points[seg+1],prev=points[max(0,seg-1)],next=points[min(points.count-1,seg+2)]
 let c1=pt(a.x+(b.x-prev.x)*0.16,a.y+(b.y-prev.y)*0.16)
 let c2=pt(b.x-(next.x-a.x)*0.16,b.y-(next.y-a.y)*0.16)
 return bezier(a,c1,c2,b,q)
}
func wake(_ c:CGContext,_ path:(Double)->Pose,_ t:Double,_ scale:Double){
 // Water stays behind past stern positions, including through turns.
 let before=path(t-0.02),after=path(t+0.02)
 let speed=hypot(Double(after.p.x-before.p.x),Double(after.p.y-before.p.y))/0.04
 let ageSpan=min(45,100*scale/max(0.1,speed))
 for side in [-1.0,1.0] {
  var a:[CGPoint]=[]
  for n in 0...28 {let age=Double(n)/28*ageSpan,p=path(t-age),distance=125*scale
   let spread=(3+Double(n)*0.32)*scale*side
   a.append(pt(p.p.x-cos(p.yaw)*distance-sin(p.yaw)*spread,p.p.y-sin(p.yaw)*distance+cos(p.yaw)*spread))}
  for n in 0..<a.count-1 {line(c,[a[n],a[n+1]],paper.withAlphaComponent(0.27*(1-Double(n)/Double(a.count))),max(0.4,scale*1.4))}
 }
 let p=path(t),bow=pt(p.p.x+cos(p.yaw)*123*scale,p.p.y+sin(p.yaw)*123*scale)
 for side in [-1.0,1.0] {let a=pt(bow.x-cos(p.yaw)*8*scale-sin(p.yaw)*6*scale*side,bow.y-sin(p.yaw)*8*scale+cos(p.yaw)*6*scale*side)
  line(c,[bow,a],paper.withAlphaComponent(0.42),max(0.5,scale*0.7))}
}
func vessel(_ c:CGContext,_ model:Model,_ path:(Double)->Pose,_ t:Double,_ scale:Double,_ name:String="",_ tint:NSColor=paper,_ trails:Bool=true){
 if trails {wake(c,path,t,scale)}
 let p=path(t);ship(c,model,p.p.x,p.p.y,scale,p.yaw,Double.pi/2,t,false)
 if !name.isEmpty {label(c,name,p.p.x,p.p.y,tint)}
}
let groups=[0.0,12,36,72,108,144,168,216,240,288,300]
func groupAt(_ t:Double)->Int {min(9,max(0,groups.lastIndex(where:{$0<=t}) ?? 0))}
struct Cam {var x:Double;var y:Double;var z:Double;var angle:Double=0}
struct Key {let t:Double;let cam:Cam}
func cat(_ a:Double,_ b:Double,_ c:Double,_ d:Double,_ q:Double)->Double {
 0.5*((2*b)+(-a+c)*q+(2*a-5*b+4*c-d)*q*q+(-a+3*b-3*c+d)*q*q*q)
}
let cameraKeys:[[Key]]=[
 [Key(t:0,cam:Cam(x:670,y:365,z:0.95)),Key(t:4,cam:Cam(x:470,y:420,z:1.4)),Key(t:8,cam:Cam(x:390,y:435,z:1.75)),Key(t:12,cam:Cam(x:680,y:375,z:0.96))],
 [Key(t:0,cam:Cam(x:680,y:375,z:0.96)),Key(t:6,cam:Cam(x:720,y:375,z:1.12)),Key(t:12,cam:Cam(x:840,y:350,z:1.65)),Key(t:18,cam:Cam(x:690,y:370,z:1.03)),Key(t:24,cam:Cam(x:680,y:370,z:0.92))],
 [Key(t:0,cam:Cam(x:760,y:365,z:0.85)),Key(t:10,cam:Cam(x:1000,y:315,z:1.25)),Key(t:20,cam:Cam(x:755,y:250,z:1.12)),Key(t:30,cam:Cam(x:460,y:280,z:1.45)),Key(t:36,cam:Cam(x:650,y:345,z:0.95))],
 [Key(t:0,cam:Cam(x:760,y:365,z:0.9)),Key(t:7,cam:Cam(x:610,y:285,z:1.25)),Key(t:13,cam:Cam(x:760,y:350,z:0.94)),Key(t:18,cam:Cam(x:865,y:410,z:1.48)),Key(t:23,cam:Cam(x:820,y:400,z:1.03)),Key(t:30,cam:Cam(x:1000,y:430,z:1.18)),Key(t:36,cam:Cam(x:780,y:365,z:0.92))],
 [Key(t:0,cam:Cam(x:580,y:370,z:0.95)),Key(t:10,cam:Cam(x:450,y:400,z:1.3)),Key(t:20,cam:Cam(x:470,y:460,z:1.1)),Key(t:28,cam:Cam(x:590,y:470,z:1.25)),Key(t:36,cam:Cam(x:730,y:440,z:1.0))],
 [Key(t:0,cam:Cam(x:650,y:350,z:0.9)),Key(t:7,cam:Cam(x:870,y:360,z:1.4)),Key(t:13,cam:Cam(x:760,y:370,z:1.0)),Key(t:19,cam:Cam(x:1100,y:325,z:1.3)),Key(t:24,cam:Cam(x:1200,y:300,z:1.05))],
 [Key(t:0,cam:Cam(x:500,y:390,z:0.9)),Key(t:10,cam:Cam(x:655,y:365,z:1.13)),Key(t:20,cam:Cam(x:790,y:355,z:1.15)),Key(t:26,cam:Cam(x:590,y:400,z:1.55)),Key(t:34,cam:Cam(x:650,y:380,z:1.5)),Key(t:39,cam:Cam(x:710,y:380,z:1.7)),Key(t:44,cam:Cam(x:810,y:365,z:1.3)),Key(t:48,cam:Cam(x:820,y:365,z:1.0))],
 [Key(t:0,cam:Cam(x:820,y:365,z:1.0)),Key(t:7,cam:Cam(x:700,y:380,z:1.8)),Key(t:13,cam:Cam(x:830,y:380,z:1.18)),Key(t:20,cam:Cam(x:780,y:380,z:0.88)),Key(t:24,cam:Cam(x:760,y:370,z:0.9))],
 [Key(t:0,cam:Cam(x:650,y:370,z:0.9)),Key(t:10,cam:Cam(x:800,y:350,z:1.08)),Key(t:19,cam:Cam(x:655,y:355,z:0.94)),Key(t:28,cam:Cam(x:860,y:365,z:1.3)),Key(t:36,cam:Cam(x:790,y:365,z:1.08)),Key(t:43,cam:Cam(x:865,y:375,z:1.5)),Key(t:48,cam:Cam(x:800,y:370,z:1.0))],
 [Key(t:0,cam:Cam(x:640,y:360,z:1.0)),Key(t:12,cam:Cam(x:640,y:360,z:1.0))]
]
func camera(_ group:Int,_ elapsed:Double)->Cam {
 let keys=cameraKeys[group];let t=max(0,min(keys.last!.t,elapsed));let i=min(keys.count-2,max(0,(keys.lastIndex(where:{$0.t<=t}) ?? 0)))
 let h=keys[i+1].t-keys[i].t,q=(t-keys[i].t)/h
 func component(_ get:(Cam)->Double)->Double {
  func derivatives(_ j:Int)->(Double,Double) {
   if j==0 || j==keys.count-1 {return (0,0)}
   let prev=keys[j-1],cur=keys[j],next=keys[j+1],left=cur.t-prev.t,right=next.t-cur.t
   let sl=(get(cur.cam)-get(prev.cam))/left,sr=(get(next.cam)-get(cur.cam))/right
   return ((get(next.cam)-get(prev.cam))/(left+right),2*(sr-sl)/(left+right))
  }
  let p0=get(keys[i].cam),p1=get(keys[i+1].cam),d0=derivatives(i),d1=derivatives(i+1)
  let a0=p0,a1=d0.0*h,a2=0.5*d0.1*h*h
  let delta=p1-a0-a1-a2,dv=d1.0*h-a1-2*a2,da=d1.1*h*h-2*a2
  let a3=10*delta-4*dv+0.5*da,a4 = -15*delta+7*dv-da,a5=6*delta-3*dv+0.5*da
  return a0+a1*q+a2*q*q+a3*q*q*q+a4*pow(q,4)+a5*pow(q,5)
 }
 return Cam(x:component{$0.x},y:component{$0.y},z:component{$0.z},angle:component{$0.angle})
}
struct Annotation {let text:String;let anchor:CGPoint;let color:NSColor}
var annotations:[Annotation]=[]
var bodyRects:[CGRect]=[]
func noteShipBody(_ p:CGPoint,_ scale:Double,_ yaw:Double){
 let input:[CGPoint]=[pt(-125,-18),pt(125,-18),pt(125,18),pt(-125,18)]
 var corners:[CGPoint]=[]
 let co:Double=cos(yaw),si:Double=sin(yaw)
 for v in input {let vx=Double(v.x),vy=Double(v.y);let x=Double(p.x)+(vx*co-vy*si)*scale;let y=Double(p.y)+(vx*si+vy*co)*scale;corners.append(screen(pt(x,y)))}
 let xs:[CGFloat]=corners.map{$0.x},ys:[CGFloat]=corners.map{$0.y}
 let minX:CGFloat=xs.min()!,minY:CGFloat=ys.min()!,width:CGFloat=xs.max()!-minX,height:CGFloat=ys.max()!-minY
 bodyRects.append(CGRect(x:minX,y:minY,width:width,height:height).insetBy(dx:-7,dy:-7))
}
var annotationCamera=Cam(x:640,y:360,z:1)
var annotationOffset=0.0
func screen(_ p:CGPoint)->CGPoint {
 let cam=annotationCamera,dx=Double(p.x)-cam.x,dy=Double(p.y)-cam.y
 return pt(640+(dx*cos(cam.angle)-dy*sin(cam.angle))*cam.z+annotationOffset,355+(dx*sin(cam.angle)+dy*cos(cam.angle))*cam.z)
}
func drawAnnotations(_ c:CGContext){
 var occupied:[CGRect]=[]
 for a in annotations {
  if a.anchor.x < -30 || a.anchor.x>1310 || a.anchor.y<103 || a.anchor.y>628 {continue}
  let width=min(225.0,max(100,Double(a.text.count)*8.2)),height=25.0
  var offsets=[pt(24,-45),pt(24,32),pt(-width-24,-45),pt(-width-24,32),pt(-width/2,-140),pt(-width/2,120)]
  if let body=bodyRects.first(where:{$0.contains(a.anchor)}) {
   offsets=[pt(body.maxX+12-a.anchor.x,body.minY-a.anchor.y),pt(body.minX-width-12-a.anchor.x,body.maxY-height-a.anchor.y),pt(body.midX-width/2-a.anchor.x,body.minY-height-12-a.anchor.y),pt(body.midX-width/2-a.anchor.x,body.maxY+12-a.anchor.y)]+offsets
  }
  var rect=CGRect.zero
  for o in offsets {
   let x=max(28,min(1252-width,Double(a.anchor.x+o.x))),y=max(115,min(590-height,Double(a.anchor.y+o.y)))
   let r=CGRect(x:x,y:y,width:width,height:height)
   if !occupied.contains(where:{$0.insetBy(dx:-10,dy:-8).intersects(r)}) && !bodyRects.contains(where:{$0.intersects(r)}) {rect=r;break}
  }
  if rect == .zero {continue};occupied.append(rect)
  let end=pt(rect.midX,rect.midY < a.anchor.y ? rect.maxY:rect.minY)
  line(c,[a.anchor,pt(end.x,end.y+(end.y<a.anchor.y ? 7:-7)),end],a.color.withAlphaComponent(0.6),0.9)
  c.setFillColor(ink.withAlphaComponent(0.8).cgColor);c.fill(rect.insetBy(dx:-5,dy:-2))
  txt(a.text,rect.minX,rect.minY,15,a.color,true,width)
 }
 annotations=[]
}
let coastlineJSON=(try! JSONSerialization.jsonObject(with:Data(contentsOf:root.appendingPathComponent("land.geojson")))) as! [String:Any]
func geo(_ lon:Double,_ lat:Double)->CGPoint {pt(640+(lon+15)*18,360-(lat-57)*18)}
let route=[geo(18.5,54.5),geo(12,54.6),geo(10.8,55.3),geo(10.4,57.7),geo(5.3,60.3),geo(-1,67),geo(-20,67),geo(-32,63),geo(-37,55),geo(-22,48),geo(-16.2,48.2)]
func routeProgress(_ t:Double,_ chase:Bool)->Double {
 let v:[Double]=chase ? [7.2,7.5,7.7,8.1,8.3,9.0,9.7]:[0.1,1.5,4.0,6.4,7.0,7.1,7.2]
 func m(_ j:Int)->Double {
  if j==0 {return (v[1]-v[0])/6};if j==6 {return (v[6]-v[5])/6}
  let a=(v[j]-v[j-1])/6,b=(v[j+1]-v[j])/6;return 2*a*b/(a+b)
 }
 if t<0 {return v[0]+t*m(0)};if t>36 {return v[6]+(t-36)*m(6)}
 let i=min(5,max(0,Int(t/6))),q=t/6-Double(i),q2=q*q,q3=q2*q
 return (2*q3-3*q2+1)*v[i]+(q3-2*q2+q)*6*m(i)+(-2*q3+3*q2)*v[i+1]+(q3-q2)*6*m(i+1)
}
func routePose(_ t:Double,_ chase:Bool,_ lag:Double=0,_ offset:Double=0)->Pose {
 movingPose({tt in
  let p=routeProgress(tt-lag,chase),a=smoothRoute(route,p),b=smoothRoute(route,p+0.002)
  let ang=atan2(Double(b.y-a.y),Double(b.x-a.x))
  return pt(a.x-sin(ang)*offset,a.y+cos(ang)*offset)
 },t)
}
func chart(_ c:CGContext){
 for feature in coastlineJSON["features"] as! [[String:Any]] {
  let g=feature["geometry"] as! [String:Any]
  let polys=g["type"] as! String == "Polygon" ? [g["coordinates"] as! [[[Double]]]] : g["coordinates"] as! [[[[Double]]]]
  for rings in polys {for ring in rings.prefix(1){let p=ring.map{geo($0[0],$0[1])};polygon(c,p,NSColor(calibratedRed:0.22,green:0.26,blue:0.23,alpha:1));line(c,p,paper.withAlphaComponent(0.24),0.85)}}
 }
 for lat in stride(from:45.0,through:75,by:5){line(c,[geo(-60,lat),geo(30,lat)],paper.withAlphaComponent(0.1),0.6)}
 for lon in stride(from:-60.0,through:30,by:10){line(c,[geo(lon,40),geo(lon,80)],paper.withAlphaComponent(0.1),0.6)}
 for (name,lon,lat) in [("GREENLAND",-44.0,70.0),("ICELAND",-21.5,66.0),("BRITAIN",-5.0,55.0),("NORWAY",8.0,65.0),("BREST",-6.0,48.4)] {let p=geo(lon,lat);txt(name,p.x,p.y,14,paper.withAlphaComponent(0.55),true,180)}
 var all:[CGPoint]=[];for i in 0...500{all.append(smoothRoute(route,Double(i)/50))}
 line(c,all,paper.withAlphaComponent(0.15),1.8)
}
func overview(_ c:CGContext,_ t:Double,_ chase:Bool){
 chart(c)
 let end=routeProgress(t,chase)
 let trail=(0...max(1,Int(end*50))).map{smoothRoute(route,Double($0)/50)}
 line(c,trail,red.withAlphaComponent(0.65),2)
 vessel(c,shipModel,{routePose($0,chase)},t,0.37,"BISMARCK",red)
 if !chase && t<22 {vessel(c,cruiserModel,{routePose($0,false,1.6,16)},t,0.3,"PRINZ EUGEN",paper)}
 if t>24 && !chase || chase && t<15 {vessel(c,cruiserModel,{routePose($0,chase,3.8,-60)},t,0.26,"SHADOWING CRUISER",blue)}
 if chase && t>24 && t<30 {let p=routePose(t,true).p;let r=25+(t-24)*8;c.setStrokeColor(gold.withAlphaComponent(0.4).cgColor);c.setLineWidth(1);c.strokeEllipse(in:CGRect(x:p.x-r,y:p.y-r,width:2*r,height:2*r))}
 if chase && t>30 {let p=forward(pt(450,330),0.18,18,t-30);aircraft(c,p.p.x,p.p.y,0.45,p.yaw,t)}
}
func attackShip(_ t:Double)->Pose {forward(pt(810,350),-0.15,1.5,t)}
func attackPlane(_ t:Double,_ n:Int)->Pose {
 movingPose({tt in
  let elapsed=tt-Double(n)*1.8
  let release=pt(565-Double(n)*40,500+Double(n)*55)
  let target=attackShip(39+Double(n)*1.8),end=pt(target.p.x-cos(target.yaw)*112,target.p.y-sin(target.yaw)*112)
  let angle=atan2(Double(end.y-release.y),Double(end.x-release.x)),speed=38.0
  if elapsed<=26 {
   let control=pt(release.x-cos(angle)*speed*26/3,release.y-sin(angle)*speed*26/3)
   return bezier(pt(-450-Double(n)*65,650+Double(n)*55),pt(-100,640+Double(n)*55),control,release,elapsed/26)
  }
  return pt(release.x+cos(angle)*speed*(elapsed-26),release.y+sin(angle)*speed*(elapsed-26))
 },t)
}
func torpedoPosition(_ t:Double)->CGPoint {
 let a=attackPlane(26,0).p,ship=attackShip(39),end=pt(ship.p.x-cos(ship.yaw)*112,ship.p.y-sin(ship.yaw)*112)
 return pt(mix(a.x,end.x,(t-26)/13),mix(a.y,end.y,(t-26)/13))
}
func damagedShip(_ t:Double)->Pose {
 let start=attackShip(48),r=280.0
 let distance=0.7*t+0.8*8*(1-exp(-t/8)),a=start.yaw+distance/r
 return Pose(p:pt(start.p.x+r*(sin(a)-sin(start.yaw)),start.p.y+r*(-cos(a)+cos(start.yaw))),yaw:a)
}
func drawWorld(_ c:CGContext,_ group:Int,_ t:Double,_ offset:Double=0){
 let e=t-groups[group],cam=camera(group,e)
 c.saveGState();c.clip(to:CGRect(x:offset,y:0,width:1280,height:720));c.translateBy(x:offset,y:0)
 annotationCamera=cam;annotationOffset=offset
 c.translateBy(x:640,y:355);c.scaleBy(x:cam.z,y:cam.z);c.rotate(by:cam.angle);c.translateBy(x:-cam.x,y:-cam.y)
 ocean(c,t,group==6 || group==7)
 switch group {
 case 0:
  let path:(Double)->Pose={forward(pt(660,360),-0.2,2,$0)}
  vessel(c,shipModel,path,e,2.6)
  if e<7 {let target=path(7),end=pt(target.p.x-cos(target.yaw)*115*2.6,target.p.y-sin(target.yaw)*115*2.6);let p=pt(mix(0,end.x,e/7),mix(600,end.y,e/7));let ang=atan2(Double(end.y-600),Double(end.x));line(c,[pt(p.x-cos(ang)*70,p.y-sin(ang)*70),p],paper.withAlphaComponent(0.6),2);line(c,[p,pt(p.x+cos(ang)*18,p.y+sin(ang)*18)],paper,4)}
  else {let p=path(e);blast(c,p.p.x-cos(p.yaw)*115*2.6,p.p.y-sin(p.yaw)*115*2.6,e-7,95,false)}
 case 1:
  let path:(Double)->Pose={forward(pt(660,360),-0.2,2,$0+12)}
  vessel(c,shipModel,path,e,2.6,"",paper,false)
  let p=path(e).p
  if e<12 {line(c,[pt(p.x-330,p.y+100),pt(p.x+330,p.y+100)],gold,1);for x in [p.x-330,p.x+330]{line(c,[pt(x,p.y+94),pt(x,p.y+106)],gold,1)}}
  if e>=12 && e<18 {for x in [72.0,46,-61,-91]{let q=path(e);let target=pt(q.p.x+cos(q.yaw)*x*2.6,q.p.y+sin(q.yaw)*x*2.6);ellipse(c,target.x,target.y,5,5,gold.withAlphaComponent(0.65))}}
  if e>=18 {label(c,"36 m BEAM",p.x,p.y+50,gold);label(c,"320 mm MAIN BELT",p.x+240,p.y+20,gold)}
 case 2:overview(c,e,false)
 case 3:denmark(c,t,min(17,Int(t/6)),e/36)
 case 4:overview(c,e,true)
 case 5:
  let carrier:(Double)->Pose={forward(pt(650,350),-0.12,2,$0)}
  wake(c,carrier,e,2.5);let cp=carrier(e)
  c.saveGState();c.translateBy(x:cp.p.x,y:cp.p.y);c.rotate(by:cp.yaw)
  polygon(c,[pt(-370,-45),pt(350,-45),pt(370,-20),pt(370,25),pt(345,45),pt(-370,45)],grey)
  for x in stride(from:-360.0,through:350,by:8){line(c,[pt(x,-43),pt(x,43)],paper.withAlphaComponent(0.13),0.4)}
  for x in stride(from:-350.0,through:350,by:38){line(c,[pt(x,0),pt(x+19,0)],paper.withAlphaComponent(0.55),1)}
  polygon(c,[pt(-15,28),pt(100,28),pt(105,47),pt(-15,47)],grey.blended(withFraction:0.3,of:.black)!)
  for n in 0..<6 {let elapsed=e-(2+Double(n)*3.6);if elapsed<0 {aircraft(c,-280+Double(n)*62,-16,0.35,0,t)} }
  c.restoreGState()
  for n in 0..<6 {let elapsed=e-(2+Double(n)*3.6);if elapsed>=0 && elapsed<14 {
   let plane=movingPose({tt in let ship=carrier(tt+2+Double(n)*3.6);let d = -280+min(tt,4)*min(tt,4)*32+max(0,tt-4)*256;return pt(ship.p.x+cos(ship.yaw)*d-sin(ship.yaw)*(-16),ship.p.y+sin(ship.yaw)*d+cos(ship.yaw)*(-16))},elapsed)
   aircraft(c,plane.p.x,plane.p.y,0.5,plane.yaw,t)
  }}
  label(c,"HMS ARK ROYAL",cp.p.x,cp.p.y+50,blue)
  if e>=6 && e<18 {vessel(c,cruiserModel,{forward(pt(1100,430),-0.12,2,$0)},e,0.6,"HMS SHEFFIELD",blue)}
 case 6:
  vessel(c,shipModel,attackShip,e,1.05,"BISMARCK",red)
  for n in 0..<3 {let p=attackPlane(e,n);if e<35 {aircraft(c,p.p.x,p.p.y,0.66-Double(n)*0.07,p.yaw,t)}}
  if e>12 && e<25 {for n in 0..<7{let age=(e+Double(n)*0.6).truncatingRemainder(dividingBy:3);blast(c,570+Double(n)*60,330+Double(n%3)*40,age,13,false)}}
  if e>=26 && e<39 {let p=torpedoPosition(e),a=torpedoPosition(e-0.5),ang=atan2(Double(p.y-a.y),Double(p.x-a.x));line(c,[a,p],paper.withAlphaComponent(0.6),1.6);line(c,[p,pt(p.x+cos(ang)*13,p.y+sin(ang)*13)],paper,3)}
  if e>=39 {let p=attackShip(39),hit=pt(p.p.x-cos(p.yaw)*112,p.p.y-sin(p.yaw)*112);blast(c,hit.x,hit.y,e-39,60,false);if e>42 {label(c,"STEERING HIT",hit.x,hit.y,gold)}}
 case 7:
  vessel(c,shipModel,damagedShip,e,1.05,"BISMARCK",red)
  if e<16 {let p=damagedShip(e),stern=pt(p.p.x-cos(p.yaw)*110,p.p.y-sin(p.yaw)*110);label(c,"RUDDERS JAMMED",stern.x,stern.y,gold)}
  if e>9 {for n in 0..<3 {
   let start=pt(350+Double(n)*330,140+Double(n%2)*350),end=pt(720+Double(n)*130,340)
   let path:(Double)->Pose={tt in movingPose({r in bezier(start,pt(start.x+140,start.y),pt(end.x-150,end.y-70),end,(r-9)/28)},tt)}
   vessel(c,cruiserModel,path,e,0.3,n==0 ? "DESTROYERS":"",blue)
  }}
 case 8:finalBattle(c,t,min(47,Int(t/6)),e/48)
 default:
  if e<6 {txt("2,000+ DEAD",310,285,74,paper,true);txt("A LITTLE OVER 100 SURVIVORS",315,380,25,paper)}
  else {txt("OPERATION",170,230,29,gold,true);txt("RHEINÜBUNG",165,270,92,paper,true);txt("18–27 MAY 1941",175,385,25,paper);txt("Sources and editable animation in the repository",175,455,16,paper.withAlphaComponent(0.65))}
 }
 c.restoreGState()
}
func smoother(_ x:Double)->Double {let q=max(0,min(1,x));return q*q*q*(q*(q*6-15)+10)}
func render(_ t:Double,_ c:CGContext){
 let group=groupAt(t),e=t-groups[group],shot=min(49,Int(t/6)),local=t-Double(shot*6)
 c.saveGState();c.translateBy(x:0,y:Double(H));c.scaleBy(x:1.5,y:-1.5)
 NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=NSGraphicsContext(cgContext:c,flipped:true)
 c.setFillColor(ink.cgColor);c.fill(CGRect(x:0,y:0,width:1280,height:720))
 annotations=[];bodyRects=[]
 c.saveGState();c.clip(to:CGRect(x:0,y:100,width:1280,height:530))
 // Actual scene-to-scene whip-pans. No opacity fade and no six-second camera restart.
 if group>0 && group != 1 && group != 7 && e<0.85 {
  let q=smoother(e/0.85)
  drawWorld(c,group-1,t,-1280*q)
  drawWorld(c,group,t,1280*(1-q))
 }else {drawWorld(c,group,t)}
 c.restoreGState();drawAnnotations(c)
 // Stable UI, independently animated captions and a thin time bar.
 c.setFillColor(ink.cgColor);c.fill(CGRect(x:0,y:0,width:1280,height:100))
 txt("RHEINÜBUNG",40,24,21,gold,true)
 let names=["26 MAY / THE DECISIVE HIT","BISMARCK / TECHNICAL PLAN","18–23 MAY / BREAKOUT","24 MAY / DENMARK STRAIT","24–26 MAY / THE CHASE","26 MAY / FORCE H","26 MAY / THE STRIKE","26–27 MAY / STEERING LOST","27 MAY / FINAL ENGAGEMENT","AFTERMATH"]
 txt(names[group],390,27,16,paper.withAlphaComponent(0.85),true,650)
 if group==3 {let sec=5*3600+52*60+Int((t-72)*30);txt(String(format:"%02d:%02d:%02d",sec/3600,(sec/60)%60,sec%60),1100,27,18,paper,true,160);txt("TIME ×30 / SHIP SYMBOLS ENLARGED",390,61,11,paper.withAlphaComponent(0.6))}
 else if group==8 {let starts=[0.0,180,480,900,1380,2640,5580,6720];let sec=8*3600+47*60+Int(starts[shot-40]+local*10);txt(String(format:"%02d:%02d:%02d",sec/3600,(sec/60)%60,sec%60),1100,27,18,paper,true,160);txt("SELECTED MOMENTS ×10 / SHIP SYMBOLS ENLARGED",390,61,11,paper.withAlphaComponent(0.6))}
 else {txt("ORIGINAL 2D PLAN ART / ILLUSTRATIVE RECONSTRUCTION",390,61,10,paper.withAlphaComponent(0.5))}
 c.setFillColor(ink.cgColor);c.fill(CGRect(x:0,y:630,width:1280,height:90))
 c.setFillColor(gold.cgColor);c.fill(CGRect(x:40,y:650,width:3,height:42))
 c.saveGState();c.clip(to:CGRect(x:60,y:637,width:1170,height:65))
 if shot>0 && local<0.32 {let q=smoother(local/0.32);txt(captions[shot-1],60,648-q*70,shot-1==5 ? 30:36,paper,true);txt(captions[shot],60,718-q*70,shot==5 ? 30:36,paper,true)}
 else {txt(captions[shot],60,648,shot==5 || shot==36 ? 30:36,paper,true)}
 c.restoreGState()
 line(c,[pt(0,718),pt(1280*t/300,718)],gold,2)
 if t>298 {c.setFillColor(NSColor.black.withAlphaComponent(smoother((t-298)/2)).cgColor);c.fill(CGRect(x:0,y:0,width:1280,height:720))}
 NSGraphicsContext.restoreGraphicsState();c.restoreGState()
}
func audit(){
 let paths:[(String,(Double)->Pose,ClosedRange<Double>)]=[
 ("breakout",{routePose($0,false)},0...36),("chase",{routePose($0,true)},0...36),
 ("escort",{routePose($0,false,1.6,16)},3...20),("shadower",{routePose($0,true,3.8,-60)},0...15),
 ("attack battleship",attackShip,0...48),("damaged battleship",damagedShip,0...24),
 ("Swordfish 1",{attackPlane($0,0)},0...35),("Swordfish 2",{attackPlane($0,1)},0...35),
 ("carrier",{forward(pt(650,350),-0.12,2,$0)},0...24)
 ]
 var total=0,maxError=0.0
 for (name,path,range) in paths {for i in 0...500 {let t=range.lowerBound+(range.upperBound-range.lowerBound)*Double(i)/500,p=path(t),a=path(t-0.003),b=path(t+0.003),dx=Double(b.p.x-a.p.x),dy=Double(b.p.y-a.p.y)
  let speed=hypot(dx,dy);if speed<1e-9 {continue}
  let alignment=(cos(p.yaw)*dx+sin(p.yaw)*dy)/speed
  let error=abs(sin(p.yaw)*dx-cos(p.yaw)*dy)/speed;maxError=max(maxError,error)
  precondition(alignment>0.999 && error<0.01,"Sideslip or reversing: \(name) at \(t)")
  precondition(p.p.x.isFinite && p.p.y.isFinite && p.yaw.isFinite)
  total+=1
 }}
 let previous=attackShip(48),following=damagedShip(0)
 precondition(hypot(Double(previous.p.x-following.p.x),Double(previous.p.y-following.p.y))<1e-8)
 let a=attackShip(47.999),b=damagedShip(0.001)
 precondition(abs(hypot(Double(previous.p.x-a.p.x),Double(previous.p.y-a.p.y))/0.001-hypot(Double(b.p.x-following.p.x),Double(b.p.y-following.p.y))/0.001)<0.01,"Speed jump at steering damage")
 let release=attackPlane(26,0),torpA=torpedoPosition(26),torpB=torpedoPosition(26.01)
 let tx=Double(torpB.x-torpA.x),ty=Double(torpB.y-torpA.y)
 precondition((cos(release.yaw)*tx+sin(release.yaw)*ty)/hypot(tx,ty)>0.999,"Torpedo reverses at release")
 print("MOTION AUDIT PASS: \(total) sampled poses, maximum sideslip ratio \(maxError); forward torpedo release")
 // Camera curves must be position-continuous across all internal keyframes.
 for group in 0..<10 {for k in cameraKeys[group].dropFirst().dropLast(){let a=camera(group,k.t-0.0001),b=camera(group,k.t+0.0001);precondition(hypot(a.x-b.x,a.y-b.y)<0.1 && abs(a.z-b.z)<0.01)}}
 for group in 0..<10 {for k in cameraKeys[group].dropFirst().dropLast(){let dt=0.0001,a=camera(group,k.t-dt),b=camera(group,k.t),c=camera(group,k.t+dt)
  precondition(abs((b.x-a.x)/dt-(c.x-b.x)/dt)<0.1 && abs((b.y-a.y)/dt-(c.y-b.y)/dt)<0.1,"Camera speed jump")
  precondition(abs((b.z-a.z)/dt-(c.z-b.z)/dt)<0.001)
 }}
 print("CAMERA AUDIT PASS: continuous position, speed and acceleration; no per-caption reset")
}
let pixels=UnsafeMutableRawPointer.allocate(byteCount:W*H*4,alignment:64)
let context=CGContext(data:pixels,width:W,height:H,bitsPerComponent:8,bytesPerRow:W*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.noneSkipFirst.rawValue)!
if CommandLine.arguments.contains("--audit") {audit()}
else if CommandLine.arguments.contains("--stills") {
 for t in [5.0,17,21,29,35.7,36.35,51,71.7,72.4,81,93,147,165,175,195,207,221,235,255,285,297] {try autoreleasepool{render(t,context);let rep=NSBitmapImageRep(cgImage:context.makeImage()!);try rep.representation(using:.png,properties:[:])!.write(to:root.appendingPathComponent("shot-\(t).png"))}}
}else{
 let ffmpeg=CommandLine.arguments[2],preview=CommandLine.arguments.contains("--preview")
 let process=Process();process.executableURL=URL(fileURLWithPath:ffmpeg)
 let output=preview ? "motion-preview.mp4":"bismarck-silent.mp4"
 process.arguments=["-y","-v","error","-f","rawvideo","-pixel_format","argb","-video_size","1920x1080","-framerate","24","-i","pipe:0","-an","-c:v","libx264","-crf","17","-preset","fast","-pix_fmt","yuv420p","-movflags","+faststart",root.appendingPathComponent(output).path]
 let pipe=Pipe();process.standardInput=pipe;try process.run()
 let ranges:[Range<Int>]=preview ? [Int(32*fps)..<Int(41*fps),Int(163*fps)..<Int(177*fps),Int(211*fps)..<Int(227*fps)]:[0..<(duration*fps)]
 for range in ranges {for frame in range {autoreleasepool{render(Double(frame)/Double(fps),context);pipe.fileHandleForWriting.write(Data(bytesNoCopy:pixels,count:W*H*4,deallocator:.none))};if frame%720==0 {print("Rendered \(frame/fps)s");fflush(stdout)}}}
 try pipe.fileHandleForWriting.close();process.waitUntilExit();precondition(process.terminationStatus==0);print("VIDEO COMPLETE")
}
pixels.deallocate()
