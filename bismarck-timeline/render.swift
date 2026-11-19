import AppKit
import CoreGraphics
import Foundation

let root=URL(fileURLWithPath:CommandLine.arguments[1])
let W=1920, H=1080, fps=24, duration=450
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
var environmentClock:Double?=nil
var narrativeClock=0.0
var suppressScriptCues=false
var explicitFuelOil=false
var suppressWorldText=false
func txt(_ s:String,_ x:Double,_ y:Double,_ size:Double,_ color:NSColor=paper,_ bold:Bool=false,_ width:Double=1150){
 if suppressWorldText{return}
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
 if kind==2 {for i in structureStart..<m.f.count {let f=m.f[i];m.f[i]=Face(v:f.v.map{V($0.x-40,$0.y,$0.z)},c:f.c)}}
 // Main turrets are drawn independently so they train toward the target.
 if kind==1 || kind==4 || kind==6 {m.cylinder(-44,0,6,4,14,15,grey);m.cylinder(-44,0,5,3,29,1.5,NSColor.black)}
 for side in [-1.0,1.0]{
  for x in [-40.0,-13.0,29.0]{m.cylinder(x,13*side,4,3,9,4,grey);m.box(x-1,13*side,9,0.6,12,0.6,grey)}
  for x in [-50.0,-27.0,3.0,35.0]{m.cylinder(x,11*side,1.7,1.7,15,2,NSColor(calibratedWhite:0.55,alpha:1))}
  for x in [-34.0,-23.0]{m.prism([pt(x-4,7*side),pt(x+4,7*side),pt(x+5,9*side),pt(x-4,10*side)],15,1,paper)}
  // Railings, anchors and capstans.
  // Railings follow the hull contour in the plan renderer.
 }
 m.cylinder(107,0,1.6,1.6,9,0.6,grey);m.box(-5,-18,1,36,15,0.7,grey)
 if kind==4 {m.f=m.f.map{Face(v:$0.v.map{V($0.x*1.046,$0.y*0.894,$0.z)},c:$0.c)}}
 if kind==6 {m.f=m.f.map{Face(v:$0.v.map{V($0.x*0.44,$0.y*0.32,$0.z*0.45)},c:$0.c)}}
 if kind==1 {m.f=m.f.map{Face(v:$0.v.map{V($0.x*factor,$0.y*0.8,$0.z*0.8)},c:$0.c)}}
 return m
}
let shipModel=makeShip(), cruiserModel=makeShip(1), rodneyModel=makeShip(2), kgvModel=makeShip(3), hoodModel=makeShip(4), destroyerModel=makeShip(6)
// Original, high-resolution 2D plan sprites; no generated imagery is used.
struct PlanSprite {let image:CGImage;let kind:Int}
func classScale(_ kind:Int)->CGPoint {if kind==6{return pt(0.44,0.32)};return kind==1 ? pt(0.82,0.8):kind==4 ? pt(1.046,0.894):pt(1,1)}
let shipOutlines=(0...6).map{kind in makeShip(kind).f[0].v.map{pt($0.x,$0.y)}}
func outlinePath(_ points:[CGPoint])->CGPath {let p=CGMutablePath();p.addLines(between:points);p.closeSubpath();return p}
let canonicalHull=outlinePath(shipOutlines[0])
let shipHullPaths=shipOutlines.map{outlinePath($0)}
let carrierHull=[pt(-370,-45),pt(350,-45),pt(370,-20),pt(370,25),pt(345,45),pt(-370,45)]
let carrierIsland=[pt(-15,28),pt(100,28),pt(105,41),pt(-15,41)]
func canonicalInside(_ p:CGPoint)->Bool {canonicalHull.contains(p)}
// Mount positions, detail geometry and deck textures all use the same class transform.
func turretAim(_ relative:Double,_ kind:Int)->Double {let s=classScale(kind);return atan2(sin(relative)/s.y,cos(relative)/s.x)}
func barrelLength(_ tx:Double,_ yy:Double,_ angle:Double)->Double {
 func fits(_ length:Double)->Bool {
  for edge in [-0.75,0.75] {let y=yy+edge,p=pt(tx+cos(angle)*length-sin(angle)*y,sin(angle)*length+cos(angle)*y);if !canonicalInside(p){return false}}
  return true
 }
 if fits(26.6){return 26.6}
 var lo=7.0,hi=26.6
 for _ in 0..<24 {let m=(lo+hi)/2;if fits(m){lo=m}else{hi=m}}
 return max(7,lo-0.2)
}
func muzzleLocal(_ kind:Int,_ tx:Double,_ yy:Double,_ relative:Double)->CGPoint {
 let a=turretAim(relative,kind),length=barrelLength(tx,yy,a),s=classScale(kind)
 return pt((tx+cos(a)*length-sin(a)*yy)*s.x,(sin(a)*length+cos(a)*yy)*s.y)
}
func makePlan(_ kind:Int)->PlanSprite {
 let width=4096,height=960
 let ctx=CGContext(data:nil,width:width,height:height,bitsPerComponent:8,bytesPerRow:width*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
 ctx.translateBy(x:2048,y:480);ctx.scaleBy(x:14,y:14)
 let model=makeShip(kind),dimensions=classScale(kind)
 ctx.scaleBy(x:dimensions.x,y:dimensions.y)
 ctx.addPath(canonicalHull);ctx.clip()
 // Select level top faces, keeping the vertical presentation strictly orthographic.
 let faces=model.f.filter{f in let z=f.v[0].z;return f.v.allSatisfy{abs($0.z-z)<0.05}}.map{f in Face(v:f.v.map{V($0.x/dimensions.x,$0.y/dimensions.y,$0.z)},c:f.c)}
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
 // Railings are inset from the actual curved sheer instead of drawn as straight outriggers.
 line(ctx,shipOutlines[0].map{pt($0.x*0.975,$0.y*0.965)}+[pt(shipOutlines[0][0].x*0.975,shipOutlines[0][0].y*0.965)],paper.withAlphaComponent(0.55),0.16)
 let img=ctx.makeImage()!
 return PlanSprite(image:img,kind:kind)
}
let plans=(0...6).map{makePlan($0)}
var aimWorld:Double?=nil
var currentTime=0.0
func ship(_ c:CGContext,_ model:Model,_ x:Double,_ y:Double,_ scale:Double,_ yaw:Double,_ elevation:Double,_ t:Double,_ wake:Bool=true){
 if presenceAuditOnly{return}
 let kind=model.kind
 noteShipBody(pt(x,y),scale,yaw)
 c.saveGState();c.translateBy(x:x,y:y);c.rotate(by:yaw);c.scaleBy(x:scale,y:scale)
 if wake {for n in 0..<13{let q=(Double(n)/13+t*0.11).truncatingRemainder(dividingBy:1);let back = -126-q*100
  line(c,[pt(back,-q*15),pt(back+15,0),pt(back,q*15)],paper.withAlphaComponent((1-q)*0.23),0.5)
 }}
 c.addPath(shipHullPaths[kind]);c.clip()
 c.setShadow(offset:CGSize(width:1,height:1),blur:1.5,color:NSColor.black.withAlphaComponent(0.4).cgColor)
 c.draw(plans[kind].image,in:CGRect(x:-2048.0/14,y:-480.0/14,width:4096.0/14,height:960.0/14));c.setShadow(offset:.zero,blur:0,color:nil)
 // Dynamic main turrets share the same hull coordinates as the static sprite.
 let dimensions=classScale(kind);c.scaleBy(x:dimensions.x,y:dimensions.y)
 let locations:[Double]=kind==2 ? [76,45,12]:kind==3 ? [72,46,-85]:[72,46,-61,-91]
 for (j,tx) in locations.enumerated(){
  let defaultA=(kind==2 || j<2) ? 0.0:Double.pi
  let aim=(aimWorld ?? (yaw+defaultA))-yaw
  let relative=abs(atan2(sin(aim),cos(aim)))
  let canBear = kind==2 && j==2 ? relative>0.61 && relative<2.53 : (j<2 || kind==2) ? relative<2.53 : relative>0.61
  let angle=turretAim(canBear ? aim:defaultA,kind)
  ellipse(c,tx,0,8.2,8.2,grey)
  c.saveGState();c.translateBy(x:tx,y:0);c.rotate(by:angle)
  polygon(c,[pt(-7,-6),pt(5,-6),pt(9,-3.5),pt(9,3.5),pt(5,6),pt(-7,6)],NSColor(calibratedWhite:0.36,alpha:1))
  line(c,[pt(-6,-5.4),pt(4,-5.4),pt(8,-3)],paper.withAlphaComponent(0.5),0.18)
  line(c,[pt(-5,4.7),pt(5,4.7)],NSColor.black.withAlphaComponent(0.5),0.14)
  for h in [-2.0,2.0]{polygon(c,[pt(-4,h-0.7),pt(-2,h-0.7),pt(-2,h+0.7),pt(-4,h+0.7)],grey)}
  let barrels:[Double]=kind==2 ? [-3,0,3]:kind==3 && j != 1 ? [-3,-1,1,3]:[-2.4,2.4]
  for yy in barrels{let length=barrelLength(tx,yy,angle);line(c,[pt(7,yy),pt(length,yy)],NSColor.darkGray,1.15);line(c,[pt(7.2,yy-0.19),pt(length-0.15,yy-0.19)],NSColor(calibratedWhite:0.67,alpha:1),0.24);ellipse(c,length,yy,0.18,0.43,NSColor.black)}
  line(c,[pt(-1,-9),pt(-1,9)],grey,0.65)
  c.restoreGState()
 }
 c.restoreGState()
}
func aircraft(_ c:CGContext,_ x:Double,_ y:Double,_ scale:Double,_ angle:Double,_ t:Double,_ carrying:Bool=true){
 c.saveGState();c.translateBy(x:x,y:y);c.rotate(by:angle);c.scaleBy(x:scale,y:scale)

 ellipse(c,3,3,32,4,NSColor.black.withAlphaComponent(0.13))
 polygon(c,[pt(-34,0),pt(24,-4),pt(38,0),pt(24,4)],grey)
 for yy in [-4.0,4.0]{polygon(c,[pt(-7,yy-39),pt(8,yy-39),pt(12,yy+39),pt(-7,yy+39)],deck);line(c,[pt(0,yy-34),pt(6,yy+34)],paper.withAlphaComponent(0.5),1)}
 polygon(c,[pt(-30,-16),pt(-24,-16),pt(-22,16),pt(-30,16)],grey)
 // Underslung torpedo sits on the centreline; it is removed only at its own release.
 if carrying {line(c,[pt(-19.2,0),pt(19,0)],NSColor(calibratedWhite:0.26,alpha:1),2.5);line(c,[pt(-17,-0.5),pt(18,-0.5)],paper.withAlphaComponent(0.5),0.4)}
 for side in [-1.0,1.0] {for y in stride(from:10.0,through:34,by:6){line(c,[pt(-6,side*y),pt(9,side*(y+2))],grey.withAlphaComponent(0.55),0.35)};line(c,[pt(-3,side*10),pt(7,side*32)],NSColor.black.withAlphaComponent(0.5),0.3)}
 ellipse(c,8,0,5,3,NSColor.black);line(c,[pt(36,-13),pt(36,13)],paper.withAlphaComponent(0.6+0.3*sin(t*70)),2)
 for side in [-1.0,1.0]{ellipse(c,1,side*29,3.8,3.8,blue);ellipse(c,1,side*29,2.5,2.5,paper);ellipse(c,1,side*29,1.3,1.3,red)}
 c.restoreGState()
}
let seaImage=NSImage(contentsOf:root.appendingPathComponent("ocean.png"))!.cgImage(forProposedRect:nil,context:nil,hints:nil)!
func ocean(_ c:CGContext,_ time:Double,_ storm:Bool=false){
 let t=environmentClock ?? time
 if presenceAuditOnly{return}
 c.setFillColor(ink.cgColor);c.fill(CGRect(x:-4096,y:-4096,width:8192,height:8192))
 c.saveGState()
 let cam=annotationCamera,z=max(1,cam.z),tile=1536/z,drift=t*0.012
 let cx=Int(floor((cam.x+drift)/tile)),cy=Int(floor((cam.y+drift*0.35)/tile))
 c.setAlpha(0.65)
 for ix in (cx-2)...(cx+2) {for iy in (cy-2)...(cy+2) {c.draw(seaImage,in:CGRect(x:Double(ix)*tile-drift,y:Double(iy)*tile-drift*0.35,width:tile,height:tile))}}
 c.restoreGState()
 let colors=[ink.cgColor,NSColor(calibratedRed:0.10,green:0.18,blue:0.20,alpha:1).cgColor] as CFArray
 let g=CGGradient(colorsSpace:CGColorSpaceCreateDeviceRGB(),colors:colors,locations:[0,1])!;c.saveGState();c.setAlpha(0.35);c.drawLinearGradient(g,start:pt(0,0),end:pt(1280,720),options:[]);c.restoreGState()
 animatedSea(c,t,storm)
}
func blast(_ c:CGContext,_ x:Double,_ y:Double,_ age:Double,_ size:Double,_ fire:Bool=false){explosion(c,pt(x,y),age,size,fire)}
func label(_ c:CGContext,_ name:String,_ x:Double,_ y:Double,_ color:NSColor){annotations.append(Annotation(text:name,anchor:screen(pt(x,y)),color:color))}
// Fifty six-second shots: concise captions, actions and camera setups.
let originalCaptions=[
 "ONE TORPEDO.","AN ENTIRE PURSUIT CHANGES.",
 "BISMARCK","250.5 m LONG","EIGHT 380 mm GUNS","30 KNOTS / TRIAL TOP SPEED ≈ 30.1",
 "18–21 MAY / BREAKOUT","TWO SHIPS. ONE MISSION.","BERGEN / SPOTTED","23 MAY / DENMARK STRAIT","SUFFOLK MAKES CONTACT","NORFOLK JOINS THE SHADOW",
 "24 MAY / 05:52","GERMAN GUNS ANSWER","FIND THE RANGE","06:01 / HOOD IS LOST","PRINCE OF WALES UNDER FIRE","06:09 / BREAK OFF",
 "THE MISSION CHANGES","PRINZ EUGEN SEPARATES","VICTORIOUS LAUNCHES","A HIT. NO STOP.","25 MAY / CONTACT LOST","26 MAY / CATALINA FINDS HER",
 "ARK ROYAL / FORCE H","FIRST STRIKE: WRONG TARGET","SHEFFIELD ESCAPES","REARM. LAUNCH AGAIN.",
 "26 MAY / DUSK","SWORDFISH CLOSE IN","LOW CLOUD. ROUGH SEA.","SWORDFISH CLOSE IN","TORPEDO AWAY","RUNNING TOWARD THE STERN","IMPACT","THE STEERING HIT",
 "POWER REMAINS. CONTROL IS LOST.","NO RELIABLE COURSE TO FRANCE","REPAIR ATTEMPTS FAIL","BRITISH DESTROYERS CLOSE",
 "27 MAY / MORNING","KING GEORGE V + RODNEY","THE GUNS OPEN","BISMARCK RETURNS FIRE","RANGE CLOSES","GUNS FALL SILENT","DORSETSHIRE / TORPEDOES","BISMARCK SINKS",
 "THE HUMAN COST","THE HUNT FOR BISMARCK"
]
struct Actor {let model:Model;let name:String;let x:Double;let y:Double;let yaw:Double;let scale:Double;let tint:NSColor;var speed:Double=0.35
 var finalTrack:Int?=nil;var turnStart:Double?=nil;var turnDuration:Double=380;var turnAngle:Double=Double.pi/2;var turnRadius:Double=260
 func pose(_ sim:Double)->Pose {
  if let index=finalTrack{return finalTrackPose(index,(sim-300)/10)}
  guard let start=turnStart,sim>start else{return forward(pt(x,y),yaw,speed,sim)}
  let origin=forward(pt(x,y),yaw,speed,start),elapsed=min(turnDuration,sim-start),angle=yaw+turnAngle*elapsed/turnDuration,r=turnAngle>=0 ? turnRadius:-turnRadius
  let p=pt(origin.p.x+r*(sin(angle)-sin(yaw)),origin.p.y+r*(-cos(angle)+cos(yaw)))
  if sim>start+turnDuration{return forward(p,angle,speed,sim-start-turnDuration)}
  return Pose(p:p,yaw:angle)
 }
 func position(_ sim:Double)->CGPoint {pose(sim).p}
}
struct Salvo {let fire:Double;let from:Int;let to:Int;let guns:Int;let hit:Bool;let serial:Int}
func waterSplash(_ c:CGContext,_ x:Double,_ y:Double,_ age:Double,_ speed:Double){
 guard age>=0 && age<8 else{return};let q=age/8
 let r=2+sqrt(q)*12
 c.setStrokeColor(paper.withAlphaComponent((1-q)*0.6).cgColor);c.setLineWidth(1);c.strokeEllipse(in:CGRect(x:x-r,y:y-r,width:r*2,height:r*2))
 for j in 0..<7{let a=Double(j)*2.399;ellipse(c,x+cos(a)*r*0.4,y+sin(a)*r*0.4,r*0.16,r*0.16,paper.withAlphaComponent((1-q)*0.9))}
}
func salvoAim(_ e:Salvo,_ a:Actor,_ b:Actor,_ future:Pose)->CGPoint {
 if !e.hit{return future.p}
 let local:CGPoint
 if b.name=="HOOD" {local=a.name=="BISMARCK" ? pt(-72,0):pt(-10,12)}
 else if b.name=="BISMARCK" && a.name=="PRINCE OF WALES" {local=e.serial==41 ? pt(102,-2):pt(-8,-13)}
 else {local=pt(20,0)}
 return worldPoint(local,future,b.scale)
}
func gunnery(_ c:CGContext,_ sim:Double,_ speed:Double,_ actors:[Actor],_ events:[Salvo],_ flight:Double){
 if presenceAuditOnly{return}
 // Fall of shot is clustered; range errors are shared by a salvo, with individual dispersion.
 for e in events {
  let age=sim-e.fire;guard age>=0 && age<max(flight+8,speed*2.4) else{continue}
  let a=actors[e.from],b=actors[e.to],shooterPose=a.pose(e.fire),futurePose=b.pose(e.fire+flight),origin=shooterPose.p,future=futurePose.p
  let intended=salvoAim(e,a,b,futurePose)
  let bearing:Double=atan2(Double(intended.y-origin.y),Double(intended.x-origin.x))
  let dir=pt(cos(bearing),sin(bearing)),normal=pt(-dir.y,dir.x)
  var offsets:[(Double,Double)] = []
  if a.model.kind==2 {
   offsets=e.guns==5 ? [(76,-3),(76,3),(12,-3),(12,3),(45,0)]:[(76,0),(12,0),(45,-3),(45,3)]
  }else if a.model.kind==3 {offsets=a.name=="PRINCE OF WALES" ? [(72,-3),(72,1),(72,3),(46,-2.4),(46,2.4)] : [(72,-3),(72,1),(46,-2.4),(-85,-3),(-85,1)]}
  else if a.model.kind==4 {offsets=[(72,-2.4),(72,2.4),(46,-2.4),(46,2.4)]}
  else {let sign=e.serial%2==0 ? -2.4:2.4;offsets=[(72,sign),(46,sign),(-61,sign),(-91,sign)]}
  for (j,gun) in offsets.prefix(e.guns).enumerated(){
   let relative=abs(atan2(sin(bearing-shooterPose.yaw),cos(bearing-shooterPose.yaw)))
   if a.model.kind==2 && gun.0==12 && relative<0.61 {continue}
   if a.model.kind != 2 && gun.0<0 && relative<0.61 {continue}
   if gun.0>0 && relative>2.53 {continue}
   let local=muzzleLocal(a.model.kind,gun.0,gun.1,bearing-shooterPose.yaw)
   let start=worldPoint(local,Pose(p:origin,yaw:shooterPose.yaw),a.scale)
   // Recoil flash lasts one frame at the displayed speed; smoke lingers separately.
   if age<max(0.12,speed/24){ellipse(c,start.x,start.y,4,4,gold.withAlphaComponent(0.8));ellipse(c,start.x,start.y,1.8,1.8,paper)}
   gunDischarge(c,start,bearing,age/speed,e.serial*17+j)
   let rangeError=Double((e.serial*7)%5-2)*35.0
   let safetySide=e.serial%2==0 ? 34.0:-34.0
   let offHull=pt(-sin(futurePose.yaw)*safetySide,cos(futurePose.yaw)*safetySide)
   let spread=sin(Double(e.serial*23+j*11))*3.5
   var end=pt(future.x+offHull.x+dir.x*(rangeError+spread)+normal.x*sin(Double(j*7+e.serial))*3,future.y+offHull.y+dir.y*(rangeError+spread)+normal.y*sin(Double(j*7+e.serial))*3)
   if e.hit && j==0 {end=intended}
   let q=min(1,age/flight)
   if age<flight {let pos=pt(mix(start.x,end.x,q),mix(start.y,end.y,q)),last=max(0,q-0.007);line(c,[pt(mix(start.x,end.x,last),mix(start.y,end.y,last)),pos],paper.withAlphaComponent(0.75),0.7)}
   else {
    let struck=actors.enumerated().first {index,target in
     if target.name=="HOOD" && e.fire+flight>660 {return false}
     return insideHull(end,target.pose(e.fire+flight),target.scale,target.model.kind)
    }
    if struck != nil {let throughBow=a.name=="PRINCE OF WALES" && e.serial==41;blast(c,end.x,end.y,(age-flight)/speed,throughBow ? 12:24,!throughBow)}
    else {waterSplash(c,end.x,end.y,age-flight,speed)}
   }
  }
 }
}
let denmarkActors=[Actor(model:shipModel,name:"BISMARCK",x:610,y:285,yaw:2.45,scale:0.90,tint:red),Actor(model:cruiserModel,name:"PRINZ EUGEN",x:432.8,y:431.7,yaw:2.45,scale:0.65,tint:red),Actor(model:hoodModel,name:"HOOD",x:880,y:425,yaw:-2.35,scale:0.90,tint:blue),Actor(model:kgvModel,name:"PRINCE OF WALES",x:1111.9,y:659.9,yaw:-2.35,scale:0.82,tint:blue,turnStart:700)]
// Selected positions digitized schematically from the published British action chart.
// Chart north is screen north; intermediate positions are interpolation, not reported fixes.
struct FinalTrack {
 let keys:[(Double,Double,Double)]
 func point(_ t:Double)->CGPoint {
  func p(_ i:Int)->CGPoint {pt(keys[i].1,keys[i].2)}
  func velocity(_ i:Int)->CGPoint {let a=max(0,i-1),b=min(keys.count-1,i+1),dt=keys[b].0-keys[a].0;return pt((p(b).x-p(a).x)/dt,(p(b).y-p(a).y)/dt)}
  let point:CGPoint
  if t<=keys[0].0 {let v=velocity(0);point=pt(p(0).x+v.x*(t-keys[0].0),p(0).y+v.y*(t-keys[0].0))}
  else if t>=keys.last!.0 {let i=keys.count-1,v=velocity(i);point=pt(p(i).x+v.x*(t-keys[i].0),p(i).y+v.y*(t-keys[i].0))}
  else {let i=min(keys.count-2,keys.lastIndex(where:{$0.0<=t})!),dt=keys[i+1].0-keys[i].0,q=(t-keys[i].0)/dt,a=p(i),b=p(i+1),va=velocity(i),vb=velocity(i+1)
   let h0=2*q*q*q-3*q*q+1,h1=q*q*q-2*q*q+q,h2 = -2*q*q*q+3*q*q,h3=q*q*q-q*q
   point=pt(h0*a.x+h1*dt*va.x+h2*b.x+h3*dt*vb.x,h0*a.y+h1*dt*va.y+h2*b.y+h3*dt*vb.y)
  }
  return pt(640+(point.x-360)*3,350+(point.y-300)*3)
 }
}
let finalTrackData:[FinalTrack]=[
 FinalTrack(keys:[(0,510,460),(3,491,454),(8,480,430),(12,482,400),(16,451,352),(20,420,336),(24,406,318),(30,374,280),(34,367,268),(36,363,266),(39,362,264),(44,361,262),(48,360,260)]),
 FinalTrack(keys:[(0,170,260),(2,210,278),(3,228,285),(8,338,291),(12,350,338),(14,372,397),(16,371,375),(20,382,337),(24,367,330),(26,350,302),(28,375,235),(29,425,245),(30,435,295),(34,430,225),(36,420,210),(39,418,190),(44,420,145),(48,447,100)]),
 FinalTrack(keys:[(0,180,288),(3,238,312),(8,287,343),(12,320,415),(16,334,465),(20,322,431),(24,319,385),(30,331,298),(34,341,245),(36,342,224),(39,358,196),(44,388,143),(48,410,104)]),
 FinalTrack(keys:[(0,350,175),(8,345,215),(16,360,240),(24,400,230),(30,442,217),(34,485,230),(39,495,224),(44,470,190),(48,450,158)]),
 FinalTrack(keys:[(0,680,510),(8,636,370),(16,594,342),(24,551,322),(30,515,311),(34,438,289),(36,418,278),(39,403,266),(40,401,242),(41,376,217),(42,345,225),(43,324,250),(44,326,284),(48,299,318)])
]
func finalTrackPose(_ index:Int,_ t:Double)->Pose {movingPose({finalTrackData[index].point($0)},t)}
let finalActors=[Actor(model:shipModel,name:"BISMARCK",x:0,y:0,yaw:0,scale:0.33,tint:red,finalTrack:0),Actor(model:rodneyModel,name:"RODNEY",x:0,y:0,yaw:0,scale:0.32,tint:blue,finalTrack:1),Actor(model:kgvModel,name:"KING GEORGE V",x:0,y:0,yaw:0,scale:0.32,tint:blue,finalTrack:2),Actor(model:cruiserModel,name:"HMS NORFOLK",x:0,y:0,yaw:0,scale:0.24,tint:blue,finalTrack:3),Actor(model:cruiserModel,name:"HMS DORSETSHIRE",x:0,y:0,yaw:0,scale:0.24,tint:blue,finalTrack:4)]

func denmarkTime(_ e:Double)->Double {
 let keys:[(Double,Double)]=[(0,0),(5,180),(9,400),(12,508),(17,540),(21,600),(36,1080)]
 if e<=0{return e*36};if e>=36{return 1080+(e-36)*32}
 let i=min(keys.count-2,keys.lastIndex(where:{$0.0<=e})!),a=keys[i],b=keys[i+1]
 return mix(a.1,b.1,(e-a.0)/(b.0-a.0))
}
func puff(_ c:CGContext,_ x:Double,_ y:Double,_ rx:Double,_ ry:Double,_ color:NSColor,_ alpha:Double){
 if alpha<=0 || rx<=0 || ry<=0{return}
 c.saveGState();c.translateBy(x:x,y:y);c.scaleBy(x:rx,y:ry)
 let cols=[color.withAlphaComponent(alpha).cgColor,color.withAlphaComponent(alpha*0.65).cgColor,color.withAlphaComponent(0).cgColor] as CFArray
 let g=CGGradient(colorsSpace:CGColorSpaceCreateDeviceRGB(),colors:cols,locations:[0,0.55,1])!
 c.drawRadialGradient(g,startCenter:.zero,startRadius:0,endCenter:.zero,endRadius:1,options:[]);c.restoreGState()
}
// Stable emission seeds: smoke grows and advects from a recorded source, never loops in place.
func smokeVariation(_ seed:Int,_ n:Int)->Double {
 let x=sin(Double(seed*131+n*79+17)*12.9898)*43758.5453
 return x-floor(x)
}
func smokeCloud(_ c:CGContext,_ origin:CGPoint,_ age:Double,_ seed:Int,_ size:Double,_ shade:Double,_ opacity:Double,_ lifetime:Double=3.5){
 if age<0 || age>lifetime || presenceAuditOnly{return}
 let q=age/lifetime,wind=pt(5.8,-2.6),growth=0.35+sqrt(max(0,age))*0.8
 for j in 0..<6 {
  let a=smokeVariation(seed,j)*Double.pi*2,r=size*(0.1+smokeVariation(seed,j+20)*0.4)*sqrt(max(0,age))
  let centre=pt(origin.x+wind.x*age+cos(a)*r,origin.y+wind.y*age+sin(a)*r*0.65)
  let radius=size*growth*(0.35+smokeVariation(seed,j+40)*0.35),path=CGMutablePath()
  var points:[CGPoint]=[]
  for k in 0..<14 {let angle=Double(k)*Double.pi/7,edge=0.76+0.24*smokeVariation(seed+j*37,k+70)
   points.append(pt(centre.x+cos(angle)*radius*edge,centre.y+sin(angle)*radius*edge*(0.6+0.35*smokeVariation(seed,j+100))))
  }
  // A rounded, asymmetric contour rather than repeated radial-gradient circles.
  path.move(to:pt((points[0].x+points[13].x)/2,(points[0].y+points[13].y)/2))
  for k in 0..<14 {let next=points[(k+1)%14];path.addQuadCurve(to:pt((points[k].x+next.x)/2,(points[k].y+next.y)/2),control:points[k])};path.closeSubpath()
  c.setFillColor(NSColor(calibratedWhite:max(0.03,min(0.85,shade+(smokeVariation(seed,j+120)-0.5)*0.16)),alpha:opacity*pow(1-q,1.5)*(0.28+smokeVariation(seed,j+140)*0.22)).cgColor);c.addPath(path);c.fillPath()
 }
}
func gunDischarge(_ c:CGContext,_ origin:CGPoint,_ bearing:Double,_ age:Double,_ seed:Int){
 if age<0 || age>2.4{return}
 if age<0.11 {let end=pt(origin.x+cos(bearing)*9,origin.y+sin(bearing)*9)
  line(c,[origin,end],gold.withAlphaComponent(1-age/0.11),2.7);ellipse(c,origin.x,origin.y,2.2,2,paper.withAlphaComponent(1-age/0.11))
 }
 let source=pt(origin.x+cos(bearing)*min(age*18,6),origin.y+sin(bearing)*min(age*18,6))
 smokeCloud(c,source,age,seed,5.5,0.58,0.38,2.4)
}
// Sparse selected heavy-AA rounds. Each airburst has a mount, muzzle flash and incoming shell.
func antiAircraft(_ c:CGContext,_ t:Double,_ shipPath:(Double)->Pose,_ scale:Double,_ planePaths:[(Double)->Pose],_ fires:[Double]){
 if presenceAuditOnly{return}
 for (i,fire) in fires.enumerated(){let age=t-fire,flight=0.43+0.16*smokeVariation(i+900,1)
  if age<0 || age>flight+2.8{continue}
  let ship=shipPath(fire),side=i%2==0 ? -1.0:1.0,mount=pt([34.0,-26,3][i%3],side*11)
  let origin=worldPoint(mount,ship,scale),target=planePaths[i%planePaths.count](fire+flight).p
  let offset=pt(11+smokeVariation(i+1000,0)*16,(i%2==0 ? -1.0:1.0)*(10+smokeVariation(i+1000,1)*14))
  let end=pt(target.x+offset.x,target.y+offset.y),bearing=atan2(end.y-origin.y,end.x-origin.x)
  let muzzle=pt(origin.x+cos(bearing)*3.3*scale,origin.y+sin(bearing)*3.3*scale)
  line(c,[origin,muzzle],paper.withAlphaComponent(0.8),0.45*scale)
  gunDischarge(c,muzzle,bearing,age,i+900)
  if age<flight {let q=age/flight,a=max(0,q-0.06);line(c,[pt(mix(muzzle.x,end.x,a),mix(muzzle.y,end.y,a)),pt(mix(muzzle.x,end.x,q),mix(muzzle.y,end.y,q))],paper.withAlphaComponent(0.72),0.6)}
  else {let life=age-flight
   if life<0.07 {ellipse(c,end.x,end.y,2,1.4,gold.withAlphaComponent(1-life/0.07))}
   smokeCloud(c,end,life,i+1700,7+smokeVariation(i+1700,0)*7,0.24+smokeVariation(i+1700,1)*0.14,0.65,2.8)
  }
 }
}
func explosion(_ c:CGContext,_ p:CGPoint,_ age:Double,_ size:Double,_ fire:Bool){
 if age<0 || age>9{return}
 let q=age/9,shock=1-exp(-age*2.8),fade=exp(-age*0.5)
 c.saveGState();c.translateBy(x:p.x,y:p.y)
 c.setStrokeColor(paper.withAlphaComponent(0.55*exp(-age*1.6)).cgColor);c.setLineWidth(max(0.4,size*0.012));c.strokeEllipse(in:CGRect(x:-size*shock,y:-size*shock*0.48,width:size*shock*2,height:size*shock*0.96))
 if fire {
  puff(c,0,0,size*0.9,size*0.5,gold,0.8*exp(-age*4))
  puff(c,0,0,size*0.32,size*0.3,paper,exp(-age*9))
  for j in 0..<22 {let a=Double(j)*2.399,v=size*(0.35+Double(j%7)*0.065),r=v*age/(1+age*0.6)
   let x=cos(a)*r,y=sin(a)*r*0.65+age*age*2
   if age<2.5 {line(c,[pt(x,y),pt(x-cos(a)*size*0.09,y-sin(a)*size*0.06)],gold.withAlphaComponent(exp(-age*1.5)),max(0.25,size*0.012))}
  }
  for j in 0..<15 {let a=Double(j)*2.399,r=size*0.32*sqrt(Double(j)/15),drift=age*size*0.08
   let x=cos(a)*r+drift,y=sin(a)*r*0.55-drift*0.7,sz=size*(0.13+0.13*age)*(0.8+Double(j%4)*0.12)
   puff(c,x,y,sz,sz*0.78,NSColor(calibratedWhite:0.10+Double(j%4)*0.035,alpha:1),0.5*(1-q)*min(1,age*3))
   if age<1.2 {puff(c,x*0.6,y*0.6,sz*0.6,sz*0.4,red,0.6*exp(-age*2))}
  }
 }else{
  for j in 0..<18 {let a=Double(j)*2.399,stretch=0.3+Double(j%5)*0.15,r=size*shock*stretch
   let x=cos(a)*r,y=sin(a)*r*0.45-age*size*0.045,sz=size*(0.08+age*0.08)
   puff(c,x,y,sz,sz*(1.9-age*0.10),paper,0.7*fade)
  }
  puff(c,0,-size*age*0.10,size*0.15*(1+age),size*0.55*(1-exp(-age*5)),paper,0.9*exp(-age))
 }
 c.restoreGState()
}
func sinkingShip(_ c:CGContext,_ model:Model,_ pose:Pose,_ scale:Double,_ age:Double,_ broken:Bool){
 let q=smoother(age/7),opacity=1-smoother((age-5)/2.8),rippleFade=exp(-max(0,age-7)/5)
 c.saveGState();c.translateBy(x:pose.p.x,y:pose.p.y);c.rotate(by:pose.yaw);c.scaleBy(x:scale,y:scale)
 for piece in 0..<(broken ? 2:1) {
  c.saveGState();let side=piece==0 ? 1.0:-1.0
  c.translateBy(x:broken ? side*q*17:0,y:q*14)
  c.rotate(by:broken ? side*q*0.23:q*0.07)
  c.scaleBy(x:1-q*0.06,y:max(0.035,1-q*0.94));c.setAlpha(opacity)
  if broken {c.clip(to:CGRect(x:piece==0 ? -48:-160,y:-80,width:piece==0 ? 220:112,height:160))}
  ship(c,model,0,0,1,0,Double.pi/2,age,false);c.restoreGState()
 }
 for j in 0..<22 {let x = -110+Double(j)*10+sin(Double(j))*q*28,y=sin(Double(j)*2.7)*(18+q*20)
  ellipse(c,x,y,0.9+q,0.5,paper.withAlphaComponent(0.35*q*(1-q*0.6)*rippleFade))
 }
 c.restoreGState()
 let radius=90*scale*(0.3+q)
 puff(c,pose.p.x,pose.p.y,radius,radius*0.4,blue,0.15*q*rippleFade)
 for j in 0..<3 {let r=radius+Double(j)*15*scale;c.setStrokeColor(paper.withAlphaComponent(0.18*q*rippleFade).cgColor);c.setLineWidth(0.7);c.strokeEllipse(in:CGRect(x:pose.p.x-r,y:pose.p.y-r*0.4,width:r*2,height:r*0.8))}
}
func hoodSection(_ c:CGContext,_ e:Double){
 let alpha=smoother((e-17)/0.7)*(1-smoother((e-23.5)/0.8));if alpha<0.001{return}
 c.saveGState();c.setAlpha(alpha)
 let box=CGRect(x:675,y:40,width:570,height:240);c.setFillColor(ink.withAlphaComponent(0.9).cgColor);c.fill(box)
 // Cutaway diagram: shell penetrates protection; probable aft-magazine ignition.
 polygon(c,[pt(700,115),pt(1205,115),pt(1205,235),pt(740,235),pt(700,205)],grey.withAlphaComponent(0.6))
 line(c,[pt(710,144),pt(1195,144)],paper.withAlphaComponent(0.7),3)
 polygon(c,[pt(758,174),pt(870,174),pt(870,224),pt(758,224)],red.withAlphaComponent(0.55))
 for x in stride(from:765.0,through:860,by:12){for y in [185.0,204]{ellipse(c,x,y,4,7,gold.withAlphaComponent(0.7))}}
 let q=smoother((e-17.2)/1.6),p=pt(mix(1050,810,q),mix(65,196,q));line(c,[pt(p.x+35,p.y-19),p],paper,2)
 explosion(c,pt(812,199),max(-1,e-19),60,true)
 c.restoreGState()
}
func radar(_ c:CGContext,_ from:CGPoint,_ target:CGPoint,_ t:Double,_ locked:Bool,_ range:Double=300){
 let a=atan2(Double(target.y-from.y),Double(target.x-from.x))
 for k in 0..<3 {let q=(t*0.45+Double(k)/3).truncatingRemainder(dividingBy:1),r=range*q
  let path=CGMutablePath();path.addArc(center:from,radius:r,startAngle:a-0.28,endAngle:a+0.28,clockwise:false)
  c.addPath(path);c.setStrokeColor((locked ? blue:gold).withAlphaComponent(0.34*(1-q)).cgColor);c.setLineWidth(1.1/max(1,annotationCamera.z));c.strokePath()
 }
 if locked {let a=0.3+0.45*pow(max(0,sin(t*2.8)),8);ellipse(c,target.x,target.y,3/max(1,annotationCamera.z),3/max(1,annotationCamera.z),blue.withAlphaComponent(a))}
}
func rain(_ c:CGContext,_ t:Double){
 let strength=smoother((t-143)/3)*(1-smoother((t-238)/3));if strength<0.001{return}
 for j in 0..<75 {let speed=190+Double(j%9)*17,length=13+Double(j%6)*5
  let phase=(t*speed+Double(j*137)).truncatingRemainder(dividingBy:900),y=phase-90,x=Double((j*239)%1450)-85-phase*0.10
  let fade=smoother((y+60)/50)*(1-smoother((y-720)/50))
  line(c,[pt(x,y),pt(x-5,y+length)],paper.withAlphaComponent((0.035+Double(j%3)*0.01)*strength*fade),0.65)
 }
}
func animatedSea(_ c:CGContext,_ t:Double,_ storm:Bool){
 let cam=annotationCamera,z=max(0.2,cam.z)
 c.saveGState();c.translateBy(x:cam.x,y:cam.y);c.rotate(by:-cam.angle);c.scaleBy(x:1/z,y:1/z)
 for j in 0..<110 {
  let row=Double(j%14),col=Double(j/14),phase=t*(storm ? 0.8:0.45)+Double(j)*1.73
  let x = -780+col*220+sin(phase*0.21)*30-cam.x*z*0.08,y = -440+row*68+sin(phase*0.18)*13-cam.y*z*0.08
  let length=35+Double(j%6)*13,alpha=(storm ? 0.09:0.045)*pow(max(0,sin(phase)),2)
  let path=CGMutablePath();path.move(to:pt(x,y));path.addCurve(to:pt(x+length,y-4),control1:pt(x+length*0.3,y-5),control2:pt(x+length*0.7,y+2))
  c.addPath(path);c.setStrokeColor(paper.withAlphaComponent(alpha).cgColor);c.setLineWidth(storm ? 1.2:0.65);c.strokePath()
 }
 c.restoreGState()
}

func denmark(_ c:CGContext,_ t:Double,_ shot:Int,_ u:Double){
 let sim=denmarkTime(t-72)
 let actors=denmarkActors
 for (i,a) in actors.enumerated(){let pose=a.pose(sim),p=pose.p;recordPresence(a.name,pose,a.scale,a.model.kind);let targetIndex=i<2 ? (sim<540 ? 2:3):(i==2 && sim<180 ? 1:0),targetActor=actors[targetIndex],targetPose=targetActor.pose(sim+32)
  var target=targetPose.p
  if i==3 {target=worldPoint(sim<400 ? pt(102,-2):pt(-8,-13),targetPose,targetActor.scale)}
  if i<2 && targetIndex==2 {target=worldPoint(i==0 ? pt(-72,0):pt(-10,12),targetPose,targetActor.scale)}
  if i<2 && targetIndex==3 {target=worldPoint(pt(20,0),targetPose,targetActor.scale)}
  aimWorld=atan2(target.y-p.y,target.x-p.x)
  let track:(Double)->Pose={r in a.pose(r*30)}
  if i==0 && sim>=342 {oilSlick(c,track,sim/30,a.scale,(sim-342)/30)}
  if i==3 && sim>=700 {smokeScreen(c,track,sim/30,a.scale,(sim-700)/30)}
  if i==2 && sim>540 {c.saveGState();c.setAlpha(exp(-(sim-540)/180));wake(c,track,18,a.scale,a.model.kind);c.restoreGState()}else{wake(c,track,sim/30,a.scale,a.model.kind)}
  if i==2 && sim>540 {sinkingShip(c,a.model,Pose(p:p,yaw:pose.yaw),a.scale,(t-89),true);blast(c,p.x-cos(pose.yaw)*72*a.scale,p.y-sin(pose.yaw)*72*a.scale,t-89,105,true)}
  else {ship(c,a.model,p.x,p.y,a.scale,pose.yaw,1.57,t,false);label(c,a.name,p.x,p.y-18,a.tint)}
 }
 aimWorld=nil
 var events:[Salvo]=[]
 for (n,fire) in [180.0,340,508,690].enumerated(){events.append(Salvo(fire:fire,from:0,to:fire<540 ? 2:3,guns:4,hit:fire==508 || fire==690,serial:n))}
 for (n,fire) in [0.0,240,420].enumerated(){events.append(Salvo(fire:fire,from:2,to:fire<180 ? 1:0,guns:4,hit:false,serial:n+20))}
 for (n,fire) in [30.0,310,430,700].enumerated(){events.append(Salvo(fire:fire,from:3,to:0,guns:5,hit:n==1 || n==2,serial:n+40))}
 events.append(Salvo(fire:170,from:1,to:2,guns:4,hit:true,serial:70))
 gunnery(c,sim,30,actors,events,32)

}
func finalBattle(_ c:CGContext,_ t:Double,_ shot:Int,_ u:Double){
 let e=t-240,sim=e*10+300,actors=finalActors
 for (i,a) in actors.enumerated(){let pose=a.pose(sim),p=pose.p;recordPresence(a.name,pose,a.scale,a.model.kind)
  let target=actors[i==0 ? (e<8 ? 1:2):0].pose(sim+22.4).p;aimWorld=atan2(target.y-p.y,target.x-p.x)
  let track:(Double)->Pose={finalTrackPose(i,$0)}
  if i==0 && e>=45 {sinkingShip(c,a.model,pose,a.scale,(e-45)*2.7,false)}else{wake(c,track,e,a.scale,a.model.kind);ship(c,a.model,p.x,p.y,a.scale,pose.yaw,1.57,t,false)}
  if i==0 && e>=8 && e<45 {let damage=smoother((e-8)/20)
   for j in 0..<3 {let birth=8+Double(j)*2.1
    if e>=birth {let age=e-birth,first=max(0,Int(ceil((age-5)/0.45))),last=Int(floor(age/0.45))
     if first<=last {for n in first...last {let time=birth+Double(n)*0.45,source=worldPoint(pt(45-Double(j)*38,0),finalTrackPose(0,time),a.scale);smokeCloud(c,source,e-time,5000+j*101+n,10*a.scale,0.13,0.45*damage,5)}}
    }
   }
  }
 }
 aimWorld=nil
 let events=[Salvo(fire:320,from:1,to:0,guns:5,hit:false,serial:100),Salvo(fire:330,from:2,to:0,guns:5,hit:true,serial:101),Salvo(fire:345,from:0,to:1,guns:4,hit:false,serial:102),Salvo(fire:365,from:3,to:0,guns:4,hit:false,serial:103),Salvo(fire:385,from:4,to:0,guns:4,hit:true,serial:104),Salvo(fire:420,from:1,to:0,guns:4,hit:true,serial:105),Salvo(fire:440,from:0,to:2,guns:2,hit:false,serial:106),Salvo(fire:485,from:2,to:0,guns:4,hit:true,serial:107),Salvo(fire:535,from:3,to:0,guns:4,hit:false,serial:108),Salvo(fire:575,from:1,to:0,guns:5,hit:true,serial:109),Salvo(fire:610,from:2,to:0,guns:2,hit:true,serial:110),Salvo(fire:630,from:4,to:0,guns:4,hit:false,serial:111)]
 gunnery(c,sim,10,actors,events,22.4)
 for n in 0..<3 {torpedo(c,finalRuns[n],e,finalContacts[n],0.33)}
}


// Motion and presentation are separate: the camera cannot change a vessel's course.
struct Pose {let p:CGPoint;let yaw:Double}
struct FleetMember {let id:String;let pose:Pose;let scale:Double;let kind:Int
 var corners:[CGPoint] {(kind==5 ? carrierHull:shipOutlines[kind]).map{worldPoint($0,pose,scale)}}
}
var presenceAuditOnly=false
var presenceRecords:[FleetMember]=[]
func recordPresence(_ id:String,_ pose:Pose,_ scale:Double,_ kind:Int){if presenceAuditOnly {presenceRecords.append(FleetMember(id:id,pose:pose,scale:scale,kind:kind))}}
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
func vessel(_ c:CGContext,_ model:Model,_ path:(Double)->Pose,_ t:Double,_ scale:Double,_ name:String="",_ tint:NSColor=paper,_ trails:Bool=true,_ id:String=""){
 let identity = !id.isEmpty ? id:!name.isEmpty ? name:model.kind==0 ? "BISMARCK":"PRINZ EUGEN"
 recordPresence(identity,path(t),scale,model.kind)
 if presenceAuditOnly{return}
 if !explicitFuelOil && model.kind==0 && identity=="BISMARCK" && narrativeClock>=108 {oilSlick(c,path,t,scale,45)}
 if trails {wake(c,path,t,scale,model.kind)}
 let p=path(t);ship(c,model,p.p.x,p.p.y,scale,p.yaw,Double.pi/2,t,false)
 if !name.isEmpty {label(c,name,p.p.x,p.p.y,tint)}
}
let groups=[0.0,36,6,72,108,144,168,216,240,288,60]
let groupOrder=[0,2,1,10,3,4,5,6,7,8,9]
func groupAt(_ t:Double)->Int {if t<6{return 0};if t<36{return 2};if t<60{return 1};if t<72{return 10};return min(9,3+max(0,[72.0,108,144,168,216,240,288].lastIndex(where:{$0<=t}) ?? 0))}
func groupEnd(_ g:Int)->Double {let i=groupOrder.firstIndex(of:g)!;return i==10 ? 300:groups[groupOrder[i+1]]}
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
func desiredCamera(_ group:Int,_ elapsed:Double)->Cam {
 if group==0 {return Cam(x:640,y:360,z:1)}
 if group==2 {let p=departurePose(elapsed),q=smoother(elapsed/30);return Cam(x:p.p.x,y:p.p.y,z:mix(11,5,q))}
 if group==1 {let p=departurePose(30+elapsed),q=smoother(elapsed/5.5);let out=smoother((elapsed-22)/2);return Cam(x:p.p.x,y:p.p.y,z:exp(mix(mix(log(5),log(220),q),log(5),out)),angle:mix(mix(0,-p.yaw,q),0,out))}
 if group==5 {let p=carrierPose(elapsed),q=smoother(elapsed/5),previous=camera(4,36),ratio=0.037/0.33
  let start=forcePoint(pt(previous.x,previous.y))
  return Cam(x:mix(start.x,Double(p.p.x),q),y:mix(start.y,Double(p.p.y),q),z:exp(mix(log(previous.z*ratio),log(3.2),q)),angle:mix(previous.angle+forceMapAngle,0,q))}
 if group==10 {let p=geo(mix(3.5,-25,smoother(elapsed/12)),mix(58.25,65,smoother(elapsed/12)));return Cam(x:p.x,y:p.y,z:mix(5,1.7,smoother(elapsed/12)))}
 if group==6 && elapsed>=28 {let p=bismarckAttackPath(elapsed),tip=runs[2].position(min(elapsed,steeringContact.time)),q=smoother((elapsed-28)/7)
  let base=interpolatedCamera(group,elapsed),stern=worldPoint(pt(-108,0),p,1.05),x=mix(base.x,Double(tip.x),q),y=mix(base.y,Double(tip.y),q),hold=smoother((elapsed-steeringContact.time)/2)
  return Cam(x:mix(x,Double(stern.x),hold),y:mix(y,Double(stern.y),hold),z:mix(base.z,3.8,q))}
 if group==7 {let p=damagedShip(elapsed),stern=worldPoint(pt(-108,0),p,1.05),q=smoother((elapsed-14)/9);return Cam(x:mix(Double(stern.x),Double(p.p.x),q),y:mix(Double(stern.y),Double(p.p.y),q),z:mix(3.8,1.2,q))}
 return interpolatedCamera(group,elapsed)
}
// Subject emphasis is a camera choice; ships are never hidden to obtain a close-up.
func fittedCamera(_ desired:Cam,_ members:[FleetMember])->Cam {
 if members.isEmpty{return desired}
 let ca=cos(desired.angle),sa=sin(desired.angle)
 var points:[CGPoint]=[]
 for member in members {for p in member.corners {let x=Double(p.x),y=Double(p.y);points.append(pt(x*ca-y*sa,x*sa+y*ca))}}
 let minX=Double(points.map{$0.x}.min()!),maxX=Double(points.map{$0.x}.max()!),minY=Double(points.map{$0.y}.min()!),maxY=Double(points.map{$0.y}.max()!)
 let zx=1150/max(0.01,maxX-minX),zy=580/max(0.01,maxY-minY)
 let z=pow(pow(desired.z,-8)+pow(zx,-8)+pow(zy,-8),-1.0/8)
 func constrain(_ value:Double,_ lo:Double,_ hi:Double)->Double {let mid=(lo+hi)/2,half=max(0.000001,(hi-lo)/2);return mid+half*tanh((value-mid)/half)}
 let x=constrain(desired.x*ca-desired.y*sa,maxX-575/z,minX+575/z)
 let y=constrain(desired.x*sa+desired.y*ca,maxY-290/z,minY+290/z)
 return Cam(x:x*ca+y*sa,y:-x*sa+y*ca,z:z,angle:desired.angle)
}
func blendCamera(_ a:Cam,_ b:Cam,_ q:Double)->Cam {Cam(x:mix(a.x,b.x,q),y:mix(a.y,b.y,q),z:mix(a.z,b.z,q),angle:mix(a.angle,b.angle,q))}
func camera(_ group:Int,_ elapsed:Double)->Cam {
 let desired=desiredCamera(group,elapsed),members=sceneFleet(group,elapsed)
 if group==5 {let framed=fittedCamera(desired,members.filter{$0.id != "BISMARCK"});return blendCamera(desired,framed,smoother(elapsed/3))}
 if group==4 {
  let local=desiredCamera(4,min(elapsed,22)),mapped=chaseMapPose(Pose(p:pt(local.x,local.y),yaw:0))
  let near=Cam(x:mapped.p.x,y:mapped.p.y,z:local.z/chaseMapScale)
  let retained=members.filter{$0.id != "PRINZ EUGEN" && $0.id != "HMS ARK ROYAL"}
  let joined=blendCamera(fittedCamera(near,members.filter{$0.id != "HMS ARK ROYAL"}),fittedCamera(near,retained),smoother((elapsed-6)/5))
  let tactical=blendCamera(joined,fittedCamera(near,retained.filter{$0.id != "PRINCE OF WALES"}),smoother((elapsed-18)/4))
  let plane=FleetMember(id:"CATALINA",pose:mapCatalinaPose(max(0,elapsed-24)),scale:0.08,kind:1)
  let search=fittedCamera(Cam(x:630,y:430,z:2.2),members.filter{["BISMARCK","HMS ARK ROYAL"].contains($0.id)}+[plane])
  return blendCamera(tactical,search,smoother((elapsed-21)/6))
 }
 if group==8 {let all=fittedCamera(Cam(x:740,y:340,z:1.6),members),active=fittedCamera(Cam(x:640,y:260,z:2.1),members.filter{!["RODNEY","KING GEORGE V"].contains($0.id)});return blendCamera(all,active,smoother((elapsed-36)/8))}
 if group==6 {let close=fittedCamera(desired,members.filter{$0.id=="BISMARCK"}),wide=fittedCamera(desired,members),enter=blendCamera(camera(5,24),wide,smoother(elapsed/8));return blendCamera(enter,close,smoother((elapsed-24)/9))}
 if group==7 {let close=fittedCamera(desired,members.filter{$0.id=="BISMARCK"}),wide=fittedCamera(desired,members.filter{!["HMS ARK ROYAL","HMS SHEFFIELD"].contains($0.id)});return blendCamera(close,wide,smoother((elapsed-18)/6))}
 return fittedCamera(desired,members)
}
func interpolatedCamera(_ group:Int,_ elapsed:Double)->Cam {
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
var annotationTime=0.0
var annotationGroup=0
var labelHistory:[String:CGRect]=[:]
var lastAnnotationTime = -100.0
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
 if abs(annotationTime-lastAnnotationTime)>0.1 {labelHistory=[:]};lastAnnotationTime=annotationTime
 for a in annotations {
  let g=annotationGroup,e=annotationTime-groups[g]
  let birth=a.text.contains("SHEFFIELD") ? 6.0:a.text=="DESTROYERS" ? 9.0:0.0
  let stagger=Double(a.text.utf8.reduce(0){($0+Int($1))%5})*0.07
  let enter=smoother((e-birth-stagger)/0.65),exit=smoother((groupEnd(g)-annotationTime)/0.65)
  let alpha=enter*exit;if alpha<0.002 {continue}
  c.saveGState();c.setAlpha(alpha)
  if a.anchor.x < -30 || a.anchor.x>1310 || a.anchor.y<103 || a.anchor.y>628 {c.restoreGState();continue}
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
  if rect == .zero {c.restoreGState();continue}
  let key="\(g):\(a.text)"
  if let old=labelHistory[key],abs(annotationTime-lastAnnotationTime)<0.1 {let q=0.2;rect.origin.x=mix(old.origin.x,rect.origin.x,q);rect.origin.y=mix(old.origin.y,rect.origin.y,q)}
  labelHistory[key]=rect;rect.origin.y += (1-enter)*9;occupied.append(rect)
  let end=pt(rect.midX,rect.midY < a.anchor.y ? rect.maxY:rect.minY)
  line(c,[a.anchor,pt(end.x,end.y+(end.y<a.anchor.y ? 7:-7)),end],a.color.withAlphaComponent(0.6),0.9)
  c.setFillColor(ink.withAlphaComponent(0.8).cgColor);c.fill(rect.insetBy(dx:-5,dy:-2))
  txt(a.text,rect.minX,rect.minY,15,a.color,true,width)
  c.restoreGState()
 }
 annotations=[]
}
let coastlineJSON=(try! JSONSerialization.jsonObject(with:Data(contentsOf:root.appendingPathComponent("land-detail.geojson")))) as! [String:Any]
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
func geographicPaths(_ filename:String)->[CGPath] {
 let data=(try! JSONSerialization.jsonObject(with:Data(contentsOf:root.appendingPathComponent(filename)))) as! [String:Any]
 var result:[CGPath]=[]
 for f in data["features"] as! [[String:Any]] {guard let g=f["geometry"] as? [String:Any],let type=g["type"] as? String else{continue}
  var rings:[[[Double]]]=[]
  if type=="Polygon" {rings=g["coordinates"] as! [[[Double]]]}
  else if type=="MultiPolygon" {rings=(g["coordinates"] as! [[[[Double]]]]).flatMap{$0}}
  else if type=="LineString" {rings=[g["coordinates"] as! [[Double]]]}
  else if type=="MultiLineString" {rings=g["coordinates"] as! [[[Double]]]}
  let path=CGMutablePath()
  for ring in rings {if !ring.contains(where:{$0[0] > -65 && $0[0]<32 && $0[1]>40 && $0[1]<81}){continue}
   for (i,v) in ring.enumerated(){let p=geo(v[0],v[1]);if i==0{path.move(to:p)}else{path.addLine(to:p)}}
   if !type.contains("Line"){path.closeSubpath()}
  };result.append(path)
 };return result
}
let landPaths=geographicPaths("land-detail.geojson"),lakePaths=geographicPaths("lakes.geojson"),riverPaths=geographicPaths("rivers.geojson")
func chart(_ c:CGContext){
 if presenceAuditOnly{return}
 let z=annotationCamera.z
 for path in landPaths {c.addPath(path);c.setFillColor(NSColor(calibratedRed:0.22,green:0.26,blue:0.23,alpha:1).cgColor);c.fillPath(using:.evenOdd);c.addPath(path);c.setStrokeColor(paper.withAlphaComponent(0.42).cgColor);c.setLineWidth(0.65/z);c.strokePath()}
 for path in lakePaths {c.addPath(path);c.setFillColor(ink.cgColor);c.fillPath(using:.evenOdd)}
 for path in riverPaths {c.addPath(path);c.setStrokeColor(blue.withAlphaComponent(0.22).cgColor);c.setLineWidth(0.35/z);c.strokePath()}
 for lat in stride(from:45.0,through:75,by:5){line(c,[geo(-60,lat),geo(30,lat)],paper.withAlphaComponent(0.1),0.6/z)}
 for lon in stride(from:-60.0,through:30,by:10){line(c,[geo(lon,40),geo(lon,80)],paper.withAlphaComponent(0.1),0.6/z)}

}
// The pair shares one arc-length track: identical travel speed and a fixed 5-unit interval.
let departureWaypoints=[geo(11.25,57.4),geo(11.3,57.7),geo(10.6,58.05),geo(9,58.05),geo(7,57.65),geo(5.3,57.8),geo(3.5,58.25)]
let departureSamples=(0...1200).map{smoothRoute(departureWaypoints,Double($0)/200)}
let departureDistances:[Double]={var d=[0.0];for i in 1..<departureSamples.count {let a=departureSamples[i-1],b=departureSamples[i];d.append(d.last!+hypot(Double(b.x-a.x),Double(b.y-a.y)))};return d}()
func departureAtDistance(_ d:Double)->Pose {
 let ds=departureDistances,total=ds.last!,n=departureSamples.count
 if d<=0 {let a=departureSamples[0],b=departureSamples[1],yaw=atan2(Double(b.y-a.y),Double(b.x-a.x));return forward(a,yaw,1,d)}
 if d>=total {let a=departureSamples[n-2],b=departureSamples[n-1],yaw=atan2(Double(b.y-a.y),Double(b.x-a.x));return forward(b,yaw,1,d-total)}
 var lo=0,hi=n-1;while hi-lo>1 {let m=(lo+hi)/2;if ds[m]<d{lo=m}else{hi=m}}
 let a=departureSamples[lo],b=departureSamples[hi],q=(d-ds[lo])/(ds[hi]-ds[lo])
 return Pose(p:pt(mix(a.x,b.x,q),mix(a.y,b.y,q)),yaw:atan2(Double(b.y-a.y),Double(b.x-a.x)))
}
func departurePose(_ t:Double,_ escort:Bool=false)->Pose {
 // Continue slowly through the specification shot; camera tracks the lead ship.
 let v=(departureDistances.last!-0.105)/27.0
 let distance:Double
 if t<24 {distance=v*t}
 else if t<=30 {let u=t-24,q=u/6;distance=v*24+v*u+(0.035-v)*6*(q*q*q-0.5*pow(q,4))}
 else {distance=departureDistances.last!+(t-30)*0.035}
 return departureAtDistance(distance-(escort ? 5:0))
}
func departure(_ c:CGContext,_ e:Double,_ specs:Bool=false){
 chart(c)
 if !specs {let count=min(1200,max(1,Int(e/30*1200)));c.saveGState();c.setLineDash(phase:0,lengths:[0.12,0.32]);c.setLineCap(.round);line(c,Array(departureSamples.prefix(count)),gold.withAlphaComponent(0.8),0.09);c.restoreGState()}
 let time=specs ? e+30:e
 vessel(c,shipModel,{departurePose($0)},time,0.012,specs ? "":"BISMARCK",red)
 vessel(c,cruiserModel,{departurePose($0,true)},time,0.012,"PRINZ EUGEN",paper)
 if specs && e>5.5 {let p=departurePose(time);c.saveGState();c.setAlpha(1-smoother((e-21.5)/0.5));c.translateBy(x:p.p.x,y:p.p.y);c.rotate(by:p.yaw);c.scaleBy(x:0.012,y:0.012)
  let q=smoother((e-5.5)/2),a = -125.0,b=mix(a,125,q)
  line(c,[pt(a,34),pt(b,34)],gold,0.45)
  for x in [a,b]{line(c,[pt(x,30),pt(x,38)],gold,0.45)}
  if q>0.8 {c.saveGState();c.setAlpha(smoother((q-0.8)/0.2));txt("250.5 m",-20,38,7,gold,true,90);c.restoreGState()}
  if e>=12 && e<18 {for x in [72.0,46,-61,-91]{ellipse(c,x,0,4,4,gold.withAlphaComponent(0.55))};txt("8 × 380 mm",-24,-40,7,gold,true,120)}
  if e>=18 {line(c,[pt(0,-18),pt(0,18)],gold,0.4);txt("36 m BEAM",-20,-40,7,gold,true,110);txt("320 mm MAIN BELT",-25,52,6,gold,true,160)}
  c.restoreGState()
 }
}
func approachPose(_ t:Double,_ escort:Bool=false)->Pose {
 let path:(Double)->CGPoint={v in
  let a=geo(3.5,58.25),b=geo(-25,65),heading=atan2(Double(b.y-a.y),Double(b.x-a.x))
  if v<0{return forward(a,heading,0.49,v).p};if v>12{return forward(b,heading,0.49,v-12).p}
  return geo(mix(3.5,-25,smoother(v/12)),mix(58.25,65,smoother(v/12)))
 }
 if !escort{return movingPose(path,t)}
 return movingPose({v in let a=movingPose(path,v);let p=forward(a.p,a.yaw,1,-20).p;return pt(p.x,p.y+4)},t)
}
func departingTrack(_ t:Double,_ split:Double,_ base:(Double)->Pose,_ end:CGPoint,_ control:CGPoint,_ finish:Double)->Pose {
 if t<=split{return base(t)}
 let start=base(split),before=base(split-0.01),dx=(start.p.x-before.p.x)/0.01,dy=(start.p.y-before.p.y)/0.01,h=finish-split
 let c1=pt(start.p.x+dx*h/3,start.p.y+dy*h/3)
 return movingPose({r in bezier(start.p,c1,control,end,(r-split)/h)},t)
}
func chaseBismarck(_ t:Double)->Pose {
 let origin=pt(800,250),heading=2.45
 if t<=12{return forward(origin,heading,9,t)}
 let start=forward(origin,heading,9,12),turnEnd=22.0,radius=260.0,delta=4.183185307179587
 func turning(_ u:Double)->Pose {let a=heading+delta*u/10;return Pose(p:pt(start.p.x+radius*(sin(a)-sin(heading)),start.p.y+radius*(-cos(a)+cos(heading))),yaw:a)}
 if t<=turnEnd{return turning(t-12)}
 let end=turning(10);return forward(end.p,end.yaw,13,t-turnEnd)
}
func shadowPose(_ t:Double,_ norfolk:Bool=false)->Pose {
 let heading=2.45,start=norfolk ? pt(1030,188):pt(925,56)
 return movingPose({r in let a=forward(start,heading,9,r),offset=sin(r*0.65)*(norfolk ? 28:60)
  return pt(a.p.x-sin(heading)*offset,a.p.y+cos(heading)*offset)},t)
}
func princeWalesShadow(_ t:Double)->Pose {
 let base:(Double)->Pose={shadowPose($0-25,true)}
 if t<=18{return base(t)}
 let start=base(18),u=min(8,t-18),a=start.yaw-Double.pi*u/8,r = -300.0
 let p=pt(start.p.x+r*(sin(a)-sin(start.yaw)),start.p.y+r*(-cos(a)+cos(start.yaw)))
 if t<=26{return Pose(p:p,yaw:a)}
 return forward(p,a,40,t-26)
}
func escapeEugen(_ t:Double)->Pose {
 let heading=2.45,start=forward(pt(800,250),heading,1,170)
 if t<=6{return forward(start.p,heading,9,t)}
 return departingTrack(t,6,{forward(start.p,heading,9,$0)},pt(-600,1000),pt(-250,850),30)
}
func mapCatalinaPose(_ t:Double)->Pose {
 let origin=geo(-7.7,54.5),end=geo(-21.83,49.55)
 return movingPose({r in
  if r<2.5{return pt(origin.x-r*r*1.1,origin.y+r*r*0.18)}
  let a=pt(origin.x-6.875,origin.y+1.125),q=(r-2.5)/8
  if q>1 {let c=geo(-19,52),vx=(end.x-c.x)*3/8,vy=(end.y-c.y)*3/8;return pt(end.x+vx*(r-10.5),end.y+vy*(r-10.5))}
  return bezier(a,geo(-11,55),geo(-19,52),end,q)
 },t)
}
func searchMap(_ c:CGContext,_ t:Double){
 chart(c)
 let bm:(Double)->Pose={r in forward(geo(-23.5,50.2),0.38,2,r)}
 let ark:(Double)->Pose={r in forward(geo(-19.7,51.3),2.4,0.8,r)}
 let kgv:(Double)->Pose={r in forward(geo(-22.65,52.18),0.7,0.9,r)}
 vessel(c,shipModel,bm,t,0.11,"BISMARCK",red)
 // Ark Royal and the closing battlefleet persist while the land-based flying boat searches.
 let ap=ark(t);recordPresence("HMS ARK ROYAL",ap,0.13,5)
 c.saveGState();c.translateBy(x:ap.p.x,y:ap.p.y);c.rotate(by:ap.yaw);c.scaleBy(x:0.13,y:0.13);polygon(c,carrierHull,grey);polygon(c,carrierIsland,paper);c.restoreGState()
 vessel(c,kgvModel,kgv,t,0.11,"KING GEORGE V",blue)
 let plane=mapCatalinaPose(t);catalina(c,plane,0.42,t)
 if t<3.5 {wake(c,{mapCatalinaPose($0)},t,0.015)}
 if t>=8 {radar(c,plane.p,bm(t).p,t,true,35)}
}
let nightApproachHeading=2.45-Double.pi/2
let nightCarrierOrigin:CGPoint={
 let impact=worldPoint(pt(20,17.5),chaseBismarck(12),0.85)
 let waterDistance=(38.0+70)*0.65/2+70*0.35
 let launchDistance=4*7.6+123+220.0*3.4+3.42
 return pt(impact.x-cos(nightApproachHeading)*(waterDistance+launchDistance),impact.y-2-sin(nightApproachHeading)*(waterDistance+launchDistance))
}()
func victoriousPose(_ t:Double)->Pose {forward(nightCarrierOrigin,nightApproachHeading,4,t)}
func nightPlanePose(_ t:Double,_ n:Int)->Pose {
 let launch=6.2+Double(n)*0.7
 return movingPose({r in
  let origin=worldPoint(pt(50-Double(n)*22,0),victoriousPose(r),1)
  if r<launch{return origin}
  let age=r-launch,ship=victoriousPose(r)
  if age<1.4 {return worldPoint(pt(mix(50-Double(n)*22,123,pow(age/1.4,2)),0),ship,1)}
  let start=worldPoint(pt(123,0),victoriousPose(launch+1.4),1)
  return forward(start,ship.yaw,220.0,age-1.4).p
 },t)
}
let nightRuns:[TorpedoRun]=(0..<3).map{n in
 let release=[11.0,12.5,14][n],p=nightPlanePose(release,n),nose=forward(p.p,p.yaw,1,3.42).p
 return TorpedoRun(plane:n,release:release,aimTime:release+2,releasePoint:nose,aim:chaseBismarck(release+2).p,heading:p.yaw,speed:n==0 ? 70:60)
}
let nightContacts:[Contact?]=nightRuns.map{run in
 var t=run.release+0.65;let step=1.0/240
 while t<24 {if let f=firstHullCrossing(run.position(t),run.position(t+step),chaseBismarck(t),0.85){return Contact(time:t+f*step,point:run.position(t+f*step))};t+=step}
 return nil
}

func victoriousScene(_ c:CGContext,_ t:Double){
 let p=victoriousPose(t);recordPresence("HMS VICTORIOUS",chaseMapPose(p),0.33*chaseMapScale,5)
 wake(c,victoriousPose,t,0.98)
 c.saveGState();c.translateBy(x:p.p.x,y:p.p.y);c.rotate(by:p.yaw);c.scaleBy(x:0.33,y:0.33);polygon(c,carrierHull,grey);polygon(c,carrierIsland,paper)
 for x in stride(from:-320.0,through:300,by:30){line(c,[pt(x,0),pt(x+15,0)],paper,1)};c.restoreGState()
 for n in 0..<3 {let p=nightPlanePose(t,n);aircraft(c,p.p.x,p.p.y,0.18,p.yaw,t,t<nightRuns[n].release);torpedo(c,nightRuns[n],t,nightContacts[n])}
}
let chaseMapScale=0.08
func chaseMapPose(_ p:Pose)->Pose {let ref=chaseBismarck(22).p,a=geo(-23.5,50.2);return Pose(p:pt(a.x+(p.p.x-ref.x)*chaseMapScale,a.y+(p.p.y-ref.y)*chaseMapScale),yaw:p.yaw)}
func searchArkPose(_ t:Double)->Pose {
 if t>=28 {return forward(geo(-19.7,51.3),2.4,0.8,t-28)}
 return movingPose({r in let a=smoother((r-18)/10);return geo(mix(-17.17,-19.7,a),mix(41.5,51.3,a))},t)
}
var forceMapAngle:Double {searchArkPose(36).yaw-carrierPose(0).yaw}
func forcePoint(_ p:CGPoint)->CGPoint {
 let ap=searchArkPose(36).p,cp=carrierPose(0).p,ratio=0.037/0.33,a=forceMapAngle,x=(p.x-ap.x)/ratio,y=(p.y-ap.y)/ratio
 return pt(cp.x+x*cos(a)+y*sin(a),cp.y-x*sin(a)+y*cos(a))
}
func forceCatalina(_ c:CGContext,_ time:Double){
 let ratio=0.037/0.33,mapPlane=mapCatalinaPose(12),p=forward(forcePoint(mapPlane.p),mapPlane.yaw-forceMapAngle,38,time)
 catalina(c,p,mix(0.20/ratio,0.45,smoother(time/5)),time)
}
func chaseScene(_ c:CGContext,_ e:Double){
 chart(c)
 vessel(c,shipModel,{chaseMapPose(chaseBismarck($0))},e,0.85*chaseMapScale,"BISMARCK",red)
 vessel(c,cruiserModel,{chaseMapPose(escapeEugen($0))},e,0.6*chaseMapScale,"PRINZ EUGEN",paper)
 vessel(c,cruiserModel,{chaseMapPose(shadowPose($0))},e,0.58*chaseMapScale,"HMS SUFFOLK",blue)
 vessel(c,cruiserModel,{chaseMapPose(shadowPose($0,true))},e,0.58*chaseMapScale,"HMS NORFOLK",blue)
 vessel(c,kgvModel,{chaseMapPose(princeWalesShadow($0))},e,0.82*chaseMapScale,"PRINCE OF WALES",blue)
 let ref=chaseBismarck(22).p,anchor=geo(-23.5,50.2)
 c.saveGState();c.translateBy(x:anchor.x,y:anchor.y);c.scaleBy(x:chaseMapScale,y:chaseMapScale);c.translateBy(x:-ref.x,y:-ref.y);victoriousScene(c,e);c.restoreGState()
 radar(c,chaseMapPose(shadowPose(e)).p,chaseMapPose(chaseBismarck(e)).p,e,e<16 && hypot(shadowPose(e).p.x-chaseBismarck(e).p.x,shadowPose(e).p.y-chaseBismarck(e).p.y)<260,260*chaseMapScale)
 if e>=16 {let ghost=chaseMapPose(chaseBismarck(16)).p,a=exp(-(e-16)*0.65);line(c,[pt(ghost.x-0.8,ghost.y-0.8),pt(ghost.x+0.8,ghost.y+0.8)],gold.withAlphaComponent(a),0.12);line(c,[pt(ghost.x-0.8,ghost.y+0.8),pt(ghost.x+0.8,ghost.y-0.8)],gold.withAlphaComponent(a),0.12)}
 let ap=searchArkPose(e);recordPresence("HMS ARK ROYAL",ap,0.037,5)
 drawCarrierHull(c,ap,0.037)
 let plane=mapCatalinaPose(max(0,e-24));catalina(c,plane,0.20,e)
 if e>=24 && e<27.5 {wake(c,{mapCatalinaPose(max(0,$0))},e-24,0.015)}
 if e>=32 {radar(c,plane.p,chaseMapPose(chaseBismarck(e)).p,e,true,35)}
}
func battleLens(_ c:CGContext,_ t:Double){
 let e=t-72;if e<11.5 || e>22.5{return}
 let alpha=smoother((e-11.5)/0.5)*(1-smoother((e-22)/0.5))
 let sim=denmarkTime(e),actors=denmarkActors,a=actors[0],b=actors[2]
 let target=worldPoint(pt(-72,0),Pose(p:b.position(540),yaw:b.yaw),b.scale),origin=worldPoint(muzzleLocal(0,72,-2.4,atan2(Double(target.y-a.position(508).y),Double(target.x-a.position(508).x))-a.yaw),Pose(p:a.position(508),yaw:a.yaw),a.scale)
 let progress=max(0,min(1,(sim-508)/32)),p=pt(mix(origin.x,target.x,progress),mix(origin.y,target.y,progress))
 c.saveGState();c.setAlpha(alpha);c.clip(to:CGRect(x:25,y:24,width:520,height:300));c.setFillColor(ink.cgColor);c.fill(CGRect(x:25,y:24,width:520,height:300))
 c.translateBy(x:285,y:174);c.scaleBy(x:3.0,y:3.0);c.translateBy(x:-p.x,y:-p.y)
 let saved=annotationCamera;annotationCamera=Cam(x:p.x,y:p.y,z:3);ocean(c,t)
 denmark(c,t,min(17,Int(t/6)),e/36)
 if sim<540 {let angle=atan2(Double(target.y-origin.y),Double(target.x-origin.x));c.saveGState();c.translateBy(x:p.x,y:p.y);c.rotate(by:angle);polygon(c,[pt(-3,-0.5),pt(1,-0.5),pt(2,0),pt(1,0.5),pt(-3,0.5)],grey);line(c,[pt(-8,0),pt(-3,0)],paper.withAlphaComponent(0.45),0.25);c.restoreGState()}
 annotationCamera=saved;c.restoreGState()
}

func carrierPose(_ t:Double)->Pose {
 if t<=52{return forward(pt(-260,520),-0.12,2,t)}
 let start=forward(pt(-260,520),-0.12,2,52),count=100,dt=(t-52)/Double(count);var p=start.p
 for j in 0..<count {let age=(Double(j)+0.5)*dt,a=mix(-0.12,Double.pi/2,smoother(age/10)),speed=mix(2,18,smoother(age/8));p.x += cos(a)*speed*dt;p.y += sin(a)*speed*dt}
 return Pose(p:p,yaw:mix(-0.12,Double.pi/2,smoother((t-52)/10)))
}
func sheffieldEarly(_ t:Double)->Pose {
 let count=80,dt=max(0,t)/Double(count);var p=pt(385,435)
 for j in 0..<count {let r=(Double(j)+0.5)*dt,a = -0.12+0.50*sin(max(0,r-8)*0.09)*smoother((r-8)/4)
  p.x += cos(a)*8*dt;p.y += sin(a)*8*dt
 }
 return Pose(p:p,yaw:-0.12+0.50*sin(max(0,t-8)*0.09)*smoother((t-8)/4))
}
func sheffieldFormation(_ t:Double)->Pose {
 if t<=24{return sheffieldEarly(t)}
 return movingPose({r in let start=sheffieldEarly(24),base=forward(start.p,start.yaw,8,r-24),lead=bismarckAttackPath(r-24),target=forward(lead.p,lead.yaw,1,-200),q=smoother((r-24)/8)
  return pt(mix(base.p.x,target.p.x,q),mix(base.p.y,target.p.y,q))},t)
}
func sheffieldPose(_ t:Double)->Pose {
 if t<=75{return sheffieldFormation(t)}
 return departingTrack(t,75,sheffieldFormation,pt(-600,300),pt(-400,400),96)
}
func preStrikeBismarck(_ t:Double)->Pose {
 let mapBM=chaseMapPose(chaseBismarck(36)),start=forcePoint(mapBM.p),end=attackShip(0),heading=mapBM.yaw-forceMapAngle
 return movingPose({r in let p=flightCurve(start,end.p,heading,end.yaw,15,0.9,r,24);return pt(p.x,p.y-300*pow(sin(Double.pi*r/24),2))},t)
}
func dorsetshirePose(_ t:Double)->Pose {finalTrackPose(4,t)}
func norfolkFinalPose(_ t:Double)->Pose {finalTrackPose(3,t)}
func deckPoint(_ x:Double,_ time:Double)->CGPoint {worldPoint(pt(x,0),carrierPose(time),1)}
func flightCurve(_ a:CGPoint,_ b:CGPoint,_ startHeading:Double,_ endHeading:Double,_ startSpeed:Double,_ endSpeed:Double,_ elapsed:Double,_ duration:Double)->CGPoint {
 let c1=pt(a.x+cos(startHeading)*startSpeed*duration/3,a.y+sin(startHeading)*startSpeed*duration/3)
 let c2=pt(b.x-cos(endHeading)*endSpeed*duration/3,b.y-sin(endHeading)*endSpeed*duration/3)
 return bezier(a,c1,c2,b,elapsed/duration)
}
func wrongRelease(_ n:Int)->Double {9+Double(n)*1.1}
func wrongRun(_ n:Int)->TorpedoRun {
 let time=wrongRelease(n),heading = -0.9+Double(n)*0.32
 let aim=pt(385+(time+4)*4+[0.0,-220,180][n],435)
 let start=pt(aim.x-cos(heading)*140,aim.y-sin(heading)*140-2)
 return TorpedoRun(plane:n,release:time,aimTime:time+4,releasePoint:start,aim:aim,heading:heading,speed:31)
}
let wrongRuns=(0..<3).map{wrongRun($0)}
func swordfishPosition(_ time:Double,_ n:Int)->CGPoint {
 let first=1+Double(n)*1.6,roll=2.0,release=wrongRelease(n),land=14+Double(n)*2.4,second=18.5+Double(n)*1.8
 let parked=20-Double(n)*22,stop=40-Double(n)*35,run=wrongRuns[n]
 if time<first {return deckPoint(parked,time)}
 if time<first+roll {let q=(time-first)/roll;return deckPoint(mix(parked,124,q*q),time)}
 let takeoff=deckPoint(124,first+roll),releaseOrigin=forward(run.releasePoint,run.heading,1,-3.42).p
 if time<release {return flightCurve(takeoff,releaseOrigin,carrierPose(first+roll).yaw,run.heading,75,38,time-first-roll,release-first-roll)}
 let landing=deckPoint(-122,land)
 if time<land {let q=(time-release)/(land-release),p=flightCurve(releaseOrigin,landing,run.heading,carrierPose(land).yaw,38,65,time-release,land-release);return pt(p.x,p.y-(110+Double(n)*60)*pow(sin(Double.pi*q),2))}
 if time<land+1.3 {let q=(time-land)/1.3;return deckPoint(mix(-122,stop,1-pow(1-q,2)),time)}
 if time<second {return deckPoint(stop,time)}
 if time<second+roll {let q=(time-second)/roll;return deckPoint(mix(stop,124,q*q),time)}
 let finalRun=runs[n],finalRelease=24+finalRun.release,end=forward(finalRun.releasePoint,finalRun.heading,1,-3.42).p
 let secondTakeoff=deckPoint(124,second+roll)
 if time<finalRelease {return flightCurve(secondTakeoff,end,carrierPose(second+roll).yaw,finalRun.heading,75,38,time-second-roll,finalRelease-second-roll)}
 return forward(end,finalRun.heading,38,time-finalRelease).p
}
func swordfishPose(_ t:Double,_ n:Int)->Pose {movingPose({swordfishPosition($0,n)},t)}
func swordfishArmed(_ t:Double,_ n:Int)->Bool {t<wrongRelease(n) || t>=15+Double(n)*2.4 && t<24+runs[n].release}
func carrierBody(_ c:CGContext,_ time:Double){
 let p=carrierPose(time);recordPresence("HMS ARK ROYAL",p,0.33,5)
 let path:(Double)->Pose=carrierPose;wake(c,path,time,0.98)
 drawCarrierHull(c,p,0.33)
}
func drawCarrierHull(_ c:CGContext,_ p:Pose,_ scale:Double){
 c.saveGState();c.translateBy(x:p.p.x,y:p.p.y);c.rotate(by:p.yaw);c.scaleBy(x:scale,y:scale)
 c.addPath(outlinePath(carrierHull));c.clip()
 polygon(c,carrierHull,grey)
 polygon(c,carrierHull.map{pt($0.x*0.985,$0.y*0.92)},deck)
 for row in -26...26 {let y=Double(row)*1.55
  for col in -20...20 {let x=Double(col)*18+Double(abs(row)%3)*6,tone=Double(abs(row*13+col*7)%8)*0.01
   c.setFillColor(NSColor(calibratedRed:0.50+tone,green:0.43+tone,blue:0.31+tone,alpha:1).cgColor);c.fill(CGRect(x:x,y:y,width:17.8,height:1.4))
  }
 }
 for x in stride(from:-345.0,through:335,by:29){line(c,[pt(x,0),pt(x+15,0)],paper.withAlphaComponent(0.75),1.2)}
 for x in [-210.0,25,225] {polygon(c,[pt(x-18,-19),pt(x+18,-19),pt(x+18,19),pt(x-18,19)],grey.withAlphaComponent(0.65));line(c,[pt(x-17,-18),pt(x+17,-18),pt(x+17,18),pt(x-17,18),pt(x-17,-18)],paper.withAlphaComponent(0.5),0.6)}
 for x in stride(from:-320.0,through:-120,by:13) {line(c,[pt(x,-29),pt(x,28)],grey.withAlphaComponent(0.8),0.6)}
 polygon(c,carrierIsland,NSColor(calibratedWhite:0.34,alpha:1))
 for x in stride(from:-10.0,through:95,by:8){polygon(c,[pt(x,29),pt(x+5,29),pt(x+5,31),pt(x,31)],ink)}
 ellipse(c,40,34,7,5,grey);ellipse(c,40,34,5,3,NSColor.black)
 line(c,[pt(0,23),pt(0,43)],grey,1);line(c,[pt(-12,34),pt(13,34)],grey,0.8)
 for side in [-1.0,1.0] {for x in stride(from:-310.0,through:310,by:30){ellipse(c,x,side*39,1.8,1.8,grey);line(c,[pt(x-3,side*41),pt(x+3,side*41)],paper.withAlphaComponent(0.6),0.5)}}
 c.restoreGState()
}
func wrongStrike(_ c:CGContext,_ t:Double){
 carrierBody(c,t);vessel(c,cruiserModel,sheffieldPose,t,0.42,"HMS SHEFFIELD",blue)
 for n in 0..<3 {let p=swordfishPose(t,n);aircraft(c,p.p.x,p.p.y,0.18,p.yaw,t,swordfishArmed(t,n))
  let run=wrongRuns[n]
  if t>=run.release {
   if n==0 {if t<run.release+0.65 {torpedo(c,run,t,nil)};explosion(c,run.position(run.release+0.65),t-run.release-0.65,17,false)}
   else {torpedo(c,run,t,nil)}
  }
 }
}
func catalina(_ c:CGContext,_ p:Pose,_ scale:Double,_ time:Double){
 c.saveGState();c.translateBy(x:p.p.x,y:p.p.y);c.rotate(by:p.yaw);c.scaleBy(x:scale,y:scale)
 // Boat hull, parasol wing, twin radial engines, wing floats and blister positions.
 polygon(c,[pt(-18,-2),pt(12,-3),pt(24,0),pt(12,3),pt(-18,2),pt(-25,0)],NSColor(calibratedWhite:0.48,alpha:1))
 polygon(c,[pt(-4,-35),pt(4,-35),pt(7,-9),pt(7,9),pt(4,35),pt(-4,35)],NSColor(calibratedWhite:0.54,alpha:1))
 for side in [-1.0,1.0] {ellipse(c,7,side*11,3.5,3,grey);line(c,[pt(11,side*11-5),pt(11,side*11+5)],paper.withAlphaComponent(0.6+0.2*sin(time*80)),0.6);line(c,[pt(-1,side*31),pt(3,side*31)],grey,2);ellipse(c,-9,side*3.5,2.8,1.8,paper.withAlphaComponent(0.45));ellipse(c,1,side*27,2,2,blue);ellipse(c,1,side*27,1.3,1.3,paper);ellipse(c,1,side*27,0.7,0.7,red)}
 polygon(c,[pt(-21,-10),pt(-16,-10),pt(-14,10),pt(-21,10)],grey)
 line(c,[pt(14,-1.7),pt(18,0),pt(14,1.7)],ink,1)
 c.restoreGState()
}

let destroyerNames=["HMS COSSACK","HMS MAORI","HMS ZULU","HMS SIKH","ORP PIORUN"]
func destroyerPose(_ t:Double,_ n:Int)->Pose {
 let starts=[pt(-600,100),pt(-500,1450),pt(1900,0),pt(1800,1150),pt(-850,500)],ends=[pt(700,270),pt(850,490),pt(1100,300),pt(1050,600),pt(600,450)]
 let a=starts[n],d=ends[n],b=pt(mix(a.x,d.x,0.4),a.y),c=pt(mix(a.x,d.x,0.75),d.y)
 return movingPose({r in bezier(a,b,c,d,r/30)},t)
}
func sceneFleet(_ group:Int,_ e:Double)->[FleetMember] {
 func member(_ id:String,_ p:Pose,_ s:Double,_ k:Int)->FleetMember {FleetMember(id:id,pose:p,scale:s,kind:k)}
 switch group {
 case 1,2:
  let t=group==1 ? e+30:e
  return [member("BISMARCK",departurePose(t),0.012,0),member("PRINZ EUGEN",departurePose(t,true),0.012,1)]
 case 10:return [member("BISMARCK",approachPose(e),0.07,0),member("PRINZ EUGEN",approachPose(e,true),0.07,1)]
 case 3:return denmarkActors.map{a in member(a.name,a.pose(denmarkTime(e)),a.scale,a.model.kind)}
 case 4:
  return [member("BISMARCK",chaseMapPose(chaseBismarck(e)),0.85*chaseMapScale,0),member("PRINZ EUGEN",chaseMapPose(escapeEugen(e)),0.6*chaseMapScale,1),member("HMS SUFFOLK",chaseMapPose(shadowPose(e)),0.58*chaseMapScale,1),member("HMS NORFOLK",chaseMapPose(shadowPose(e,true)),0.58*chaseMapScale,1),member("PRINCE OF WALES",chaseMapPose(princeWalesShadow(e)),0.82*chaseMapScale,3),member("HMS VICTORIOUS",chaseMapPose(victoriousPose(e)),0.33*chaseMapScale,5),member("HMS ARK ROYAL",searchArkPose(e),0.037,5)]
 case 5:return [member("HMS ARK ROYAL",carrierPose(e),0.33,5),member("HMS SHEFFIELD",sheffieldPose(e),0.42,1),member("BISMARCK",preStrikeBismarck(e),1.05,0)]
 case 6:return [member("BISMARCK",bismarckAttackPath(e),1.05,0),member("HMS ARK ROYAL",carrierPose(e+24),0.33,5),member("HMS SHEFFIELD",sheffieldPose(e+24),0.42,1)]
 case 7:return [member("BISMARCK",damagedShip(e),1.05,0),member("HMS ARK ROYAL",carrierPose(e+72),0.33,5),member("HMS SHEFFIELD",sheffieldPose(e+72),0.42,1)]+(0..<5).map{member(destroyerNames[$0],destroyerPose(e,$0),1,6)}
 case 8:return finalActors.map{a in member(a.name,a.pose(e*10+300),a.scale,a.model.kind)}
 default:return []
 }
}
// The rendered hull polygon is also the collision hull. Projectiles never use the label or sprite rectangle.
let collisionHulls=shipOutlines
func hullLocal(_ p:CGPoint,_ pose:Pose,_ scale:Double)->CGPoint {
 let x=Double(p.x-pose.p.x)/scale,y=Double(p.y-pose.p.y)/scale
 return pt(x*cos(pose.yaw)+y*sin(pose.yaw),-x*sin(pose.yaw)+y*cos(pose.yaw))
}
func worldPoint(_ p:CGPoint,_ pose:Pose,_ scale:Double)->CGPoint {
 pt(pose.p.x+(p.x*cos(pose.yaw)-p.y*sin(pose.yaw))*scale,pose.p.y+(p.x*sin(pose.yaw)+p.y*cos(pose.yaw))*scale)
}
func insideHull(_ p:CGPoint,_ pose:Pose,_ scale:Double,_ kind:Int=0)->Bool {
 let q=hullLocal(p,pose,scale),v=shipOutlines[kind];var inside=false
 for i in v.indices {let a=v[i],b=v[(i+1)%v.count]
  if (a.y>q.y) != (b.y>q.y) && q.x<(b.x-a.x)*(q.y-a.y)/(b.y-a.y)+a.x {inside.toggle()}
 }
 return inside
}
func firstHullCrossing(_ a:CGPoint,_ b:CGPoint,_ pose:Pose,_ scale:Double,_ kind:Int=0)->Double? {
 let p=hullLocal(a,pose,scale),q=hullLocal(b,pose,scale),r=pt(q.x-p.x,q.y-p.y),v=shipOutlines[kind]
 if insideHull(a,pose,scale,kind){return 0}
 var hit:Double?=nil
 for i in v.indices {let u=v[i],w=v[(i+1)%v.count],s=pt(w.x-u.x,w.y-u.y)
  let den=Double(r.x*s.y-r.y*s.x);if abs(den)<1e-12 {continue}
  let d=pt(u.x-p.x,u.y-p.y),t=Double(d.x*s.y-d.y*s.x)/den,k=Double(d.x*r.y-d.y*r.x)/den
  if t>=0 && t<=1 && k>=0 && k<=1 {hit=min(hit ?? 1,t)}
 }
 return hit
}
struct TorpedoRun {
 let plane:Int;let release:Double;let aimTime:Double;let releasePoint:CGPoint;let aim:CGPoint;let heading:Double;let speed:Double
 func distance(_ age:Double)->Double {let entry=0.65,v0=38.0
  if age<=entry {return v0*age-0.5*(v0-speed)*age*age/entry}
  return (v0+speed)*entry/2+speed*(age-entry)
 }
 func position(_ time:Double)->CGPoint {let s=distance(max(0,time-release));return pt(releasePoint.x+cos(heading)*s,releasePoint.y+sin(heading)*s+2*ease((time-release)/0.65))}
}
struct Contact {let time:Double;let point:CGPoint}
func attackShip(_ t:Double)->Pose {forward(pt(810,350),-0.15,0.9,t)}
func makeRun(_ n:Int)->TorpedoRun {
 let release=[24.0,25.8,27.6][n],impact=[36.0,39.0,41.5][n]
 let start=[pt(565,500),pt(505,550),pt(565,205)][n]
 let local=[pt(2,18),pt(-170,-65),pt(-112,-7.0)][n]
 let aim=worldPoint(local,attackShip(impact),1.05)
 let heading=atan2(Double(aim.y-start.y-2),Double(aim.x-start.x)),d=hypot(Double(aim.x-start.x),Double(aim.y-start.y-2)),entry=0.65
 let speed=(d-0.5*38*entry)/(impact-release-0.5*entry)
 return TorpedoRun(plane:n,release:release,aimTime:impact,releasePoint:start,aim:aim,heading:heading,speed:speed)
}
let runs=(0..<3).map{makeRun($0)}
func sweptContact(_ run:TorpedoRun,_ path:(Double)->Pose)->Contact? {
 let step=1.0/240;var t=run.release+0.65
 while t<49 {let next=t+step,a=run.position(t),b=run.position(next),p0=path(t),p1=path(next)
  // Account for target translation before intersecting its instantaneous hull.
  let adjusted=pt(b.x-(p1.p.x-p0.p.x),b.y-(p1.p.y-p0.p.y))
  if let f=firstHullCrossing(a,adjusted,p0,1.05) {return Contact(time:t+step*f,point:run.position(t+step*f))}
  t=next
 }
 return nil
}
// Dorsetshire: two starboard-side runs, then a third after passing around the bow.
let finalRuns:[TorpedoRun]=(0..<3).map{n in
 let release=[39.0,39.35,44][n],impact=[40.1,40.5,44.85][n],ship=dorsetshirePose(release),target=worldPoint(pt(n==0 ? 22:n==1 ? -22:0,n<2 ? 15:-15),finalTrackPose(0,impact),0.33)
 let local=hullLocal(target,ship,0.24),origin=worldPoint(pt(0,local.y>0 ? 10:-10),ship,0.24)
 let dx=target.x-origin.x,dy=target.y-origin.y-2,heading=atan2(dy,dx),distance=hypot(dx,dy),speed=(distance-0.5*38*0.65)/(impact-release-0.325)
 return TorpedoRun(plane:n,release:release,aimTime:impact,releasePoint:origin,aim:target,heading:heading,speed:speed)
}
let finalContacts:[Contact?]=finalRuns.map{run in
 var t=run.release+0.65;let step=1.0/480
 while t<run.release+3 {if let f=firstHullCrossing(run.position(t),run.position(t+step),finalTrackPose(0,t),0.33){return Contact(time:t+f*step,point:run.position(t+f*step))};t+=step}
 return nil
}
let initialContacts=runs.map{sweptContact($0,attackShip)}
let steeringContact=initialContacts[2]!
func bismarckAttackPath(_ t:Double)->Pose {
 if t<=steeringContact.time {return attackShip(t)}
 let d=t-steeringContact.time,start=attackShip(steeringContact.time),r=280.0
 let distance=0.4*d+0.5*8*(1-exp(-d/8)),a=start.yaw+distance/r
 return Pose(p:pt(start.p.x+r*(sin(a)-sin(start.yaw)),start.p.y+r*(-cos(a)+cos(start.yaw))),yaw:a)
}
let contacts=runs.map{sweptContact($0,bismarckAttackPath)}
func damagedShip(_ t:Double)->Pose {bismarckAttackPath(48+t)}
func attackPlane(_ t:Double,_ n:Int)->Pose {swordfishPose(t+24,n)}
func torpedoPosition(_ t:Double)->CGPoint {runs[2].position(t)}
func torpedoFoam(_ c:CGContext,_ run:TorpedoRun,_ time:Double,_ contact:Contact?,_ scale:Double=1){
 let end=min(time,contact?.time ?? time),age=time-end
 guard time>run.release+0.65 && age<11 else{return}
 let maxAge=min(8.0,end-run.release-0.65)
 for j in 0..<48 {
  let a=Double(j)/48*maxAge,b=Double(j+1)/48*maxAge
  let p=run.position(end-a),q=run.position(end-b),opacity=exp(-(a+age)/4)*0.24
  let width=(0.45+a*0.22)*scale
  line(c,[p,q],paper.withAlphaComponent(opacity),width)
  let off=sin(Double(j)*2.4+Double(run.plane))*width*0.45
  ellipse(c,p.x-sin(run.heading)*off,p.y+cos(run.heading)*off,width*0.23,width*0.23,paper.withAlphaComponent(opacity*0.7))
 }
}
func torpedo(_ c:CGContext,_ run:TorpedoRun,_ time:Double,_ contact:Contact?,_ scale:Double=1){
 guard time>=run.release else{return}
 torpedoFoam(c,run,time,contact,scale)
 if let impact=contact,time>=impact.time {blast(c,impact.point.x,impact.point.y,time-impact.time,run.plane==2 ? 43:30,false);return}
 let p=run.position(time),age=time-run.release
 if age>22 {return}
 c.saveGState();c.translateBy(x:p.x,y:p.y);c.rotate(by:run.heading);c.scaleBy(x:scale,y:scale)
 c.setAlpha(age<0.65 ? 0.95:0.68)
 // 6.9-m body, 45-cm diameter; the leading tip is the collision point.
 c.setFillColor(NSColor(calibratedRed:0.23,green:0.27,blue:0.25,alpha:1).cgColor)
 c.addPath(CGPath(roundedRect:CGRect(x:-6.9,y:-0.225,width:6.9,height:0.45),cornerWidth:0.225,cornerHeight:0.225,transform:nil));c.fillPath()
 line(c,[pt(-6.3,-0.11),pt(-0.6,-0.11)],paper.withAlphaComponent(0.65),0.08)
 polygon(c,[pt(-6,-0.65),pt(-6.7,-0.65),pt(-6.5,0.65),pt(-6,0.65)],grey)
 line(c,[pt(-6.9,-0.35),pt(-6.9,0.35)],paper.withAlphaComponent(0.5),0.1)
 c.restoreGState()
 if age>=0.65 && age<1.6 {waterSplash(c,run.position(run.release+0.65).x,run.position(run.release+0.65).y,(age-0.65)*4,1)}
}
// One continuous foam mesh, tied to past stern positions. No random/frame-based particles.
func wake(_ c:CGContext,_ path:(Double)->Pose,_ t:Double,_ scale:Double,_ kind:Int=0){
 if presenceAuditOnly{return}
 let dimensions=classScale(kind),length=max(0.01,300*scale*dimensions.x),sternLength=123*dimensions.x,breadth=dimensions.y
 var positions:[Pose]=[path(t)],ages=[0.0],distances=[0.0],distance=0.0
 for j in 1...180 {let age=Double(j)*0.25,p=path(t-age),prev=positions.last!,segment=hypot(p.p.x-prev.p.x,p.p.y-prev.p.y)
  if distance+segment>=length && segment>1e-9 {let q=(length-distance)/segment,point=pt(mix(prev.p.x,p.p.x,q),mix(prev.p.y,p.p.y,q));positions.append(Pose(p:point,yaw:mix(prev.yaw,p.yaw,q)));ages.append(mix(ages.last!,age,q));distances.append(length);break}
  distance+=segment;positions.append(p);ages.append(age);distances.append(distance)
 }
 var left:[CGPoint]=[],right:[CGPoint]=[],mid:[CGPoint]=[]
 for i in positions.indices {let p=positions[i],q=distances[i]/length,width=(2.5+14*q)*scale*breadth,stern=worldPoint(pt(-sternLength,0),p,scale)
  mid.append(stern);left.append(pt(stern.x-sin(p.yaw)*width,stern.y+cos(p.yaw)*width));right.append(pt(stern.x+sin(p.yaw)*width,stern.y-cos(p.yaw)*width))
 }
 if positions.count>1 {for i in 0..<(positions.count-1) {let q=distances[i]/length,fade=pow(max(0,1-q),1.8)*pow(max(0,1-ages[i]/45),1.2)
  polygon(c,[left[i],left[i+1],right[i+1],right[i]],paper.withAlphaComponent(0.22*fade));line(c,[mid[i],mid[i+1]],paper.withAlphaComponent(0.12*fade),max(0.001,scale*breadth*0.6))
  line(c,[left[i],left[i+1]],paper.withAlphaComponent(0.13*fade),max(0.001,scale*breadth*0.5));line(c,[right[i],right[i+1]],paper.withAlphaComponent(0.13*fade),max(0.001,scale*breadth*0.5))
 }}
 let p=path(t)
 for side in [-1.0,1.0] {line(c,[worldPoint(pt(120*dimensions.x,side*3*breadth),p,scale),worldPoint(pt(100*dimensions.x,side*11*breadth),p,scale)],paper.withAlphaComponent(0.25),max(0.001,scale*breadth*0.6))}
}

func drawWorld(_ c:CGContext,_ group:Int,_ t:Double,_ offset:Double=0){
 let e=t-groups[group],cam=camera(group,e)
 c.saveGState();c.clip(to:CGRect(x:offset,y:0,width:1280,height:720));c.translateBy(x:offset,y:0)
 annotationCamera=cam;annotationOffset=offset
 c.translateBy(x:640,y:355);c.scaleBy(x:cam.z,y:cam.z);c.rotate(by:cam.angle);c.translateBy(x:-cam.x,y:-cam.y)
 ocean(c,t,group>=5 && group<=8)
 suppressWorldText = group != 0
 switch group {
 case 0:
  txt("OPERATION",170,230,29,gold,true);txt("RHEINÜBUNG",165,270,92,paper,true);txt("18–27 MAY 1941",175,385,25,paper)
 case 1:departure(c,e,true)
 case 2:departure(c,e)
 case 10:
  chart(c)
  vessel(c,shipModel,{approachPose($0)},e,0.07,"BISMARCK",red)
  vessel(c,cruiserModel,{approachPose($0,true)},e,0.07,"PRINZ EUGEN",paper)
  let suffolk:(Double)->Pose={forward(geo(-26.5,66.0),2.45,0.02,$0)},norfolk:(Double)->Pose={forward(geo(-25.5,64.0),2.45,0.02,$0)}
  vessel(c,cruiserModel,suffolk,e,0.07,"HMS SUFFOLK",blue);vessel(c,cruiserModel,norfolk,e,0.07,"HMS NORFOLK",blue)
  let p=approachPose(e),range=hypot(p.p.x-suffolk(e).p.x,p.p.y-suffolk(e).p.y)
  radar(c,suffolk(e).p,p.p,e,range<70,70)
 case 3:denmark(c,t,min(17,Int(t/6)),e/36)
 case 4:chaseScene(c,e)
 case 5:wrongStrike(c,e);vessel(c,shipModel,preStrikeBismarck,e,mix(0.85*chaseMapScale/(0.037/0.33),1.05,smoother(e/5)),"BISMARCK",red);forceCatalina(c,e)
 case 6:
  vessel(c,shipModel,bismarckAttackPath,e,1.05,"BISMARCK",red)
  forceCatalina(c,e+24);carrierBody(c,e+24);vessel(c,cruiserModel,{sheffieldPose($0+24)},e,0.42,"HMS SHEFFIELD",blue)
  for n in 0..<3 {let p=attackPlane(e,n);aircraft(c,p.p.x,p.p.y,0.18,p.yaw,t,e<runs[n].release)}
  for n in 0..<3 {torpedo(c,runs[n],e,contacts[n])}
  antiAircraft(c,e,bismarckAttackPath,1.05,(0..<3).map{n in {attackPlane($0,n)}},[9.15,10.3,12.65,15.4,18.2,21.8,24.1,27.4,30.15])
 case 7:
  vessel(c,shipModel,damagedShip,e,1.05,e<15 ? "":"BISMARCK",red)
  for n in 0..<3 {torpedoFoam(c,runs[n],48+e,contacts[n])}
  forceCatalina(c,e+72);carrierBody(c,e+72);vessel(c,cruiserModel,{sheffieldPose($0+72)},e,0.42,"HMS SHEFFIELD",blue)
  for n in 0..<5 {vessel(c,destroyerModel,{destroyerPose($0,n)},e,1,destroyerNames[n],blue)}
 case 8:finalBattle(c,t,min(47,Int(t/6)),e/48)
 default:
  if e<6 {txt("2,000+ DEAD",310,285,74,paper,true);txt("A LITTLE OVER 100 SURVIVORS",315,380,25,paper)}
  else {txt("OPERATION",170,230,29,gold,true);txt("RHEINÜBUNG",165,270,92,paper,true);txt("18–27 MAY 1941",175,385,25,paper);txt("Sources and editable animation in the repository",175,455,16,paper.withAlphaComponent(0.65))}
 }
 suppressWorldText=false
 c.restoreGState()
}
func smoother(_ x:Double)->Double {let q=max(0,min(1,x));return q*q*q*(q*(q*6-15)+10)}
let captions=Array(["OPERATION RHEINÜBUNG","LEAVING EUROPE","BISMARCK + PRINZ EUGEN","CLEAR OF THE NARROWS","INTO THE NORTH SEA","OPEN WATER","BISMARCK","250.5 m OVERALL","EIGHT 380 mm GUNS","36 m BEAM / 320 mm MAIN BELT","21 MAY / NORWEGIAN WATERS","23 MAY / DENMARK STRAIT"]+originalCaptions.dropFirst(12))
// A schematic explains the loss of steering without asserting an unrecorded damage geometry.
func steeringCutaway(_ c:CGContext,_ e:Double){
 let enter=smoother((e-1.2)/1.0),exit=smoother((15-e)/1.0),alpha=enter*exit
 if alpha<0.001{return}
 c.saveGState();c.setAlpha(alpha);c.translateBy(x:(1-enter)*700,y:0)
 let panel=CGRect(x:600,y:120,width:640,height:480)
 c.setFillColor(ink.withAlphaComponent(0.96).cgColor);c.fill(panel);line(c,[pt(600,120),pt(1240,120)],gold,2)
 txt("STERN / STEERING DAMAGE",625,137,24,gold,true)
 txt("SCHEMATIC RECONSTRUCTION",625,173,12,paper.withAlphaComponent(0.6),true)
 // Side section: stern at left, bow to right, waterline and steering compartment.
 line(c,[pt(625,300),pt(1215,300)],blue.withAlphaComponent(0.6),1)
 polygon(c,[pt(650,247),pt(1188,247),pt(1188,370),pt(720,370),pt(677,342),pt(650,300)],grey.withAlphaComponent(0.6))
 polygon(c,[pt(681,290),pt(805,290),pt(805,353),pt(720,353),pt(690,330)],blue.withAlphaComponent(0.45))
 line(c,[pt(677,260),pt(805,260),pt(805,352)],paper.withAlphaComponent(0.7),2)
 line(c,[pt(722,275),pt(722,405)],paper,4)
 polygon(c,[pt(707,364),pt(735,364),pt(744,401),pt(708,401)],red)
 polygon(c,[pt(666,320),pt(701,316),pt(715,344),pt(731,350),pt(715,361),pt(694,343)],red)
 line(c,[pt(782,347),pt(1165,347)],grey,5)
 ellipse(c,782,347,3,19,paper)
 txt("FLOODED STEERING FLAT",850,263,16,blue,true,340)
 line(c,[pt(844,284),pt(786,318)],blue,1)
 txt("DEFORMED STERN / BLOCKED TRAVEL",825,383,15,red,true,375)
 line(c,[pt(819,394),pt(731,354)],red,1)
 // Plan: three propeller shafts, two stocks; dashed neutral/commanded travel.
 txt("PLAN / TWIN RUDDERS",625,439,14,gold,true)
 for y in [493.0,521,549] {line(c,[pt(920,y),pt(1160,y)],grey,4);ellipse(c,920,y,3,14,paper)}
 for y in [506.0,536] {
  ellipse(c,790,y,4,4,paper)
  c.saveGState();c.setLineDash(phase:0,lengths:[4,4]);line(c,[pt(790,y),pt(735,y)],paper.withAlphaComponent(0.55),7);c.restoreGState()
  let q=smoother((e-2.5)/2.5),a = -0.38*q
  line(c,[pt(790,y),pt(790-55*cos(a),y-55*sin(a))],red,8)
 }
 line(c,[pt(724,508),pt(746,516),pt(752,544)],red,4)
 txt("NEUTRAL",632,560,12,paper.withAlphaComponent(0.6),true,120)
 txt("STEERING CANNOT RETURN TO CENTRE",822,571,14,red,true,385)
 c.restoreGState()
}

let scriptCues:[(Double,String)]=[
 (0,"Operation Rheinübung · 18–27 May 1941"),(6,"20 May · leaving Europe"),(24,"North Sea · clear of the narrows"),(36,"Bismarck · technical inspection"),
 (60,"21–23 May · passage toward Denmark Strait"),(70,"HMS Suffolk · radar contact"),(71,"HMS Norfolk · joins the shadow"),(72,"24 May · Denmark Strait"),(84,"Bismarck · decisive salvo"),(88,"Shell penetration · probable aft-magazine ignition"),(90,"Hood · aft magazine explosion"),(101,"Prince of Wales · breaking off"),
 (108,"24 May · Prinz Eugen separates"),(114,"Victorious · Swordfish night strike"),(120,"25 May · HMS Suffolk + HMS Norfolk zigzag"),(123,"HMS Suffolk · radar contact at extreme range"),(126,"Bismarck turns astern · Suffolk loses contact"),
 (129,"HMS Suffolk + HMS Norfolk search · Prince of Wales departs"),(132,"26 May · Catalina leaves Lough Erne"),(138,"Catalina · visual contact regained"),(144,"Ark Royal · first strike launches"),(153,"Mistaken target · HMS Sheffield evades"),(156,"Premature magnetic pistols · remaining torpedoes evaded"),(161,"Return, rearm · second strike"),
 (168,"Swordfish · approach to Bismarck"),(192,"Torpedoes away"),(207,"Stern hit · steering disabled"),(217,"Steering damage · schematic section"),(231,"British destroyers close through the night"),
 (240,"27 May · Rodney and King George V close"),(252,"Selected salvos · progressive damage"),(276,"Dorsetshire · torpedo attack"),(282,"Bismarck sinks · British ships remain afloat")]
func renderBase(_ t:Double,_ c:CGContext){
 narrativeClock=t
 let group=groupAt(t),e=t-groups[group]
 c.saveGState();c.translateBy(x:0,y:Double(H));c.scaleBy(x:1.5,y:-1.5)
 NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=NSGraphicsContext(cgContext:c,flipped:true)
 c.setFillColor(ink.cgColor);c.fill(CGRect(x:0,y:0,width:1280,height:720))
 annotations=[];bodyRects=[];annotationTime=t;annotationGroup=group
 if t<289 {
  let worldTime=min(t,287.999),worldGroup=groupAt(worldTime)
  // Changes of date/location retain the whole outgoing scene as it leaves the frame.
  if group>0 && ![1,2,3,5,6,7].contains(group) && e<0.85 {
   let q=smoother(e/0.85),previous=groupOrder[max(0,groupOrder.firstIndex(of:group)!-1)]
   if group==4 {drawFuelWorld(c,54+e,-1280*q)}else{drawWorld(c,previous,min(t,groupEnd(previous)-0.001),-1280*q)};drawWorld(c,group,t,1280*(1-q))
  }else {drawWorld(c,t>=288 ? worldGroup:group,worldTime)}
  if group==2 && e<1.1 {drawWorld(c,0,5.999,-1280*smoother(e/1.1))}
  if group==3 {bowHitLens(c,t);battleLens(c,t);if e>17 && e<25 {hoodSection(c,e)}}
  if group==7 {suppressWorldText=true;steeringCutaway(c,e);suppressWorldText=false}
  if group==8 {suppressWorldText=false;finalShipNames(c,e)}
  rain(c,t)
  // No ship-name leaders, header, footer, progress bar or large narration cards.
  if !suppressScriptCues,let cue=scriptCues.last(where:{$0.0<=t}) {let alpha=min(1,(t-cue.0)/0.35);c.saveGState();c.setAlpha(alpha)
   c.setFillColor(ink.withAlphaComponent(0.72).cgColor);c.fill(CGRect(x:22,y:670,width:min(800,Double(cue.1.count)*8.4+24),height:30))
   txt(cue.1,34,674,15,paper,false,1150);c.restoreGState()}
  if t>=288 {c.setFillColor(NSColor.black.withAlphaComponent(smoother((t-288)/0.8)).cgColor);c.fill(CGRect(x:0,y:0,width:1280,height:720))}
 }else {
  c.setFillColor(NSColor.black.cgColor);c.fill(CGRect(x:0,y:0,width:1280,height:720))
  let a=smoother((t-289)/0.5)*(1-smoother((t-293.4)/0.6))
  if t<294 {c.saveGState();c.setAlpha(a);txt("2,000+ DEAD",320,280,65,paper,true);txt("~100 SURVIVORS",326,375,29,paper);c.restoreGState()}
  else {c.saveGState();c.setAlpha(smoother((t-294)/0.65));txt("OPERATION RHEINÜBUNG",230,280,57,paper,true);txt("18–27 MAY 1941",237,370,27,gold);c.restoreGState()}
 }
 NSGraphicsContext.restoreGraphicsState();c.restoreGState()
}
// Film clock: the earlier action remains on its tested local clocks, with new approach and damage chapters.
let mapBattleRatio=0.07/0.90
let battleMapAnchor=geo(-31.8,63.3)
func battleToMap(_ p:CGPoint)->CGPoint {pt(battleMapAnchor.x+(p.x-610)*mapBattleRatio,battleMapAnchor.y+(p.y-285)*mapBattleRatio)}
func mapBattleCamera()->Cam {let c=camera(3,0),p=battleToMap(pt(c.x,c.y));return Cam(x:p.x,y:p.y,z:c.z/mapBattleRatio,angle:c.angle)}
struct ArcTrack {
 let points:[CGPoint];let distances:[Double]
 init(_ points:[CGPoint]) {self.points=points;var d=[0.0];for i in 1..<points.count {d.append(d.last!+hypot(points[i].x-points[i-1].x,points[i].y-points[i-1].y))};distances=d}
 var length:Double {distances.last!}
 func pose(_ distance:Double)->Pose {
  if distance<=0 {let a=points[0],b=points[1];return forward(a,atan2(Double(b.y-a.y),Double(b.x-a.x)),1,distance)}
  if distance>=length {let a=points[points.count-2],b=points.last!;return forward(b,atan2(Double(b.y-a.y),Double(b.x-a.x)),1,distance-length)}
  var lo=0,hi=points.count-1;while hi-lo>1 {let m=(lo+hi)/2;if distances[m]<distance{lo=m}else{hi=m}}
  let a=points[lo],b=points[hi],q=(distance-distances[lo])/max(1e-9,distances[hi]-distances[lo])
  return Pose(p:pt(mix(a.x,b.x,q),mix(a.y,b.y,q)),yaw:atan2(Double(b.y-a.y),Double(b.x-a.x)))
 }
}
func hermite(_ a:Double,_ b:Double,_ va:Double,_ vb:Double,_ span:Double,_ q:Double)->Double {
 let q2=q*q,q3=q2*q;return (2*q3-3*q2+1)*a+(q3-2*q2+q)*span*va+(-2*q3+3*q2)*b+(q3-q2)*span*vb
}
let germanApproachTrack:ArcTrack={
 let a=approachPose(12).p,heading=approachPose(11.99).yaw,d=battleMapAnchor,b=forward(a,heading,1,24).p,cp=forward(d,2.45,1,-30).p
 return ArcTrack((0...1000).map{bezier(a,b,cp,d,Double($0)/1000)})
}()
let britishApproachTrack:ArcTrack={
 let origin=geo(-3.5,60.4),a=geo(-22.5,62.5),b=geo(-27,60.6),end=battleToMap(denmarkActors[2].position(0)),heading = -2.35,lineStart=forward(end,heading,1,-50).p
 let parallel=atan2(Double(b.y-a.y),Double(b.x-a.x)),c1=geo(-10,62),c2=forward(a,parallel,1,-20).p
 var points=(0...800).map{bezier(origin,c1,c2,a,Double($0)/800)}
 points += (1...250).map{pt(mix(a.x,b.x,Double($0)/250),mix(a.y,b.y,Double($0)/250))}
 let t1=forward(b,parallel,1,10).p,t2=forward(lineStart,heading,1,-20).p
 points += (1...300).map{bezier(b,t1,t2,lineStart,Double($0)/300)}
 points += (1...250).map{pt(mix(lineStart.x,end.x,Double($0)/250),mix(lineStart.y,end.y,Double($0)/250))}
 return ArcTrack(points)
}()
let britishApproachKnotDistances=[0.0,britishApproachTrack.distances[800],britishApproachTrack.distances[1050],britishApproachTrack.distances[1350],britishApproachTrack.length]
func britishDistance(_ e:Double)->Double {
 let ts=[0.0,28,40,48,60],vel=[12.0,5,5,5,0.49],ds=britishApproachKnotDistances
 if e<=0{return e*vel[0]};if e>=60{return ds[4]+(e-60)*vel[4]}
 let i=min(3,ts.lastIndex(where:{$0<=e})!),h=ts[i+1]-ts[i]
 return hermite(ds[i],ds[i+1],vel[i],vel[i+1],h,(e-ts[i])/h)
}
func approachingHood(_ e:Double,_ pow:Bool=false)->Pose {
 let a=denmarkActors[2].position(0),b=denmarkActors[3].position(0),lag=hypot(b.x-a.x,b.y-a.y)*mapBattleRatio
 return britishApproachTrack.pose(britishDistance(e)-(pow ? lag:0))
}
func approachingGerman(_ e:Double,_ eugen:Bool=false)->Pose {
 movingPose({t in
  let q=t/60,progress=hermite(0,1,0.003,0.005444444,60,q),d=t<0 ? t*0.49:germanApproachTrack.length*progress
  if !eugen{return germanApproachTrack.pose(d).p}
  let phase=smoother((t-14)/24),lead=mix(-20,230*mapBattleRatio,phase),p=germanApproachTrack.pose(d+lead),lateral=8*sin(Double.pi*phase)
  return pt(p.p.x-sin(p.yaw)*lateral,p.p.y+cos(p.yaw)*lateral+4*(1-phase))
 },e)
}
func approachingCruiser(_ e:Double,_ norfolk:Bool=false)->Pose {
 let start=forward(norfolk ? geo(-25.5,64):geo(-26.5,66),2.45,0.02,12).p
 let end=battleToMap(norfolk ? pt(1700,0):pt(1500,-600)),c1=forward(start,2.45,1,12).p,c2=forward(end,2.45,1,-12).p
 return movingPose({r in bezier(start,c1,c2,end,r/60)},e)
}
func approachFleet(_ e:Double)->[FleetMember] {
 let size=mix(0.014,mapBattleRatio,smoother(e/26)),eugenScale=mix(0.07,0.65*mapBattleRatio,smoother((e-38)/12))
 return [FleetMember(id:"BISMARCK",pose:approachingGerman(e),scale:0.07,kind:0),FleetMember(id:"PRINZ EUGEN",pose:approachingGerman(e,true),scale:eugenScale,kind:1),FleetMember(id:"HOOD",pose:approachingHood(e),scale:0.90*size,kind:4),FleetMember(id:"PRINCE OF WALES",pose:approachingHood(e,true),scale:0.82*size,kind:3),FleetMember(id:"HMS SUFFOLK",pose:approachingCruiser(e),scale:0.07,kind:1),FleetMember(id:"HMS NORFOLK",pose:approachingCruiser(e,true),scale:0.07,kind:1)]
}
func longApproachCamera(_ e:Double)->Cam {
 let begin=camera(10,12),target=mapBattleCamera(),fleet=Array(approachFleet(e).prefix(4))
 let wide=fittedCamera(Cam(x:620,y:290,z:1.45),fleet)
 let desired=blendCamera(blendCamera(begin,wide,smoother(e/10)),target,smoother((e-40)/20))
 let fitted=fittedCamera(desired,fleet)
 return blendCamera(blendCamera(begin,fitted,smoother(e/6)),desired,smoother((e-58)/2))
}
func beginWorld(_ c:CGContext,_ cam:Cam,_ offset:Double){
 c.saveGState();c.clip(to:CGRect(x:offset,y:0,width:1280,height:720));c.translateBy(x:offset,y:0)
 annotationCamera=cam;annotationOffset=offset
 c.translateBy(x:640,y:355);c.scaleBy(x:cam.z,y:cam.z);c.rotate(by:cam.angle);c.translateBy(x:-cam.x,y:-cam.y)
}
func drawLongApproach(_ c:CGContext,_ e:Double,_ offset:Double=0){
 let cam=longApproachCamera(e);beginWorld(c,cam,offset);ocean(c,72+e,false);chart(c)
 let routeAlpha=1-smoother((e-32)/8)
 if routeAlpha>0 {c.saveGState();c.setLineDash(phase:0,lengths:[1.2,1.8]);let origin=geo(-3.1,58.85)
  let leadIn=[origin,geo(-3.8,59.2),geo(-4.3,59.8),britishApproachTrack.points[0]]
  let count=max(1,min(britishApproachTrack.points.count,Int(Double(britishApproachTrack.points.count)*max(0,min(1,britishDistance(e)/britishApproachTrack.length)))))
  line(c,leadIn+britishApproachTrack.points.prefix(count),blue.withAlphaComponent(routeAlpha*0.6),0.6/max(1,cam.z));c.restoreGState();ellipse(c,origin.x,origin.y,2/max(1,cam.z),2/max(1,cam.z),blue.withAlphaComponent(routeAlpha))
 }
 let fleet=approachFleet(e)
 let models=[shipModel,cruiserModel,hoodModel,kgvModel,cruiserModel,cruiserModel]
 for i in fleet.indices {let item=fleet[i],path:(Double)->Pose={t in approachFleet(t)[i].pose};vessel(c,models[i],path,e,item.scale,item.id,i<2 ? red:blue)}
 let s=approachingCruiser(e),b=approachingGerman(e);radar(c,s.p,b.p,e,true,70)
 c.restoreGState()
}
func oilSlick(_ c:CGContext,_ path:(Double)->Pose,_ t:Double,_ scale:Double,_ elapsed:Double){
 if presenceAuditOnly || elapsed<=0{return}
 let duration=min(45,elapsed),steps=96
 var left:[CGPoint]=[],right:[CGPoint]=[]
 for j in 0...steps {let age=duration*Double(j)/Double(steps),p=path(t-age),stern=worldPoint(pt(-123,-5),p,scale),width=(5+age*0.42)*scale
  let centre=pt(stern.x+age*0.14,stern.y+age*0.09)
  left.append(pt(centre.x-sin(p.yaw)*width,centre.y+cos(p.yaw)*width));right.append(pt(centre.x+sin(p.yaw)*width,centre.y-cos(p.yaw)*width))
 }
 for j in 0..<steps {let q=Double(j)/Double(steps);polygon(c,[left[j],left[j+1],right[j+1],right[j]],NSColor(calibratedRed:0.035,green:0.035,blue:0.025,alpha:0.43*(1-q*0.65)))
  line(c,[left[j],left[j+1]],gold.withAlphaComponent(0.07*(1-q)),max(0.12,scale*0.55));line(c,[right[j],right[j+1]],blue.withAlphaComponent(0.10*(1-q)),max(0.12,scale*0.55))
 }
 let p=path(t);line(c,[worldPoint(pt(103,-8),p,scale),worldPoint(pt(20,-18),p,scale),worldPoint(pt(-123,-5),p,scale)],NSColor.black.withAlphaComponent(0.25),max(0.2,scale*1.4))
}
func smokeScreen(_ c:CGContext,_ path:(Double)->Pose,_ t:Double,_ scale:Double,_ elapsed:Double,_ emitFor:Double=19){
 if presenceAuditOnly || elapsed<=0{return}
 let start=t-elapsed,first=max(0,Int(ceil((elapsed-7)/0.31))),last=max(0,Int(floor(min(elapsed,emitFor)/0.31)))
 if first>last{return}
 for j in first...last {let birth=start+Double(j)*0.31,age=t-birth
  let funnel=worldPoint(pt(-11,0),path(birth),scale)
  smokeCloud(c,funnel,age,j+3200,9*scale,0.25,0.35,7)
 }
}

func fuelPose(_ e:Double,_ index:Int)->Pose {
 let actor=denmarkActors[index],start=actor.pose(1080)
 if e<0 && index != 2{return actor.pose(1080+16*e)}
 if index==3{return forward(start.p,start.yaw,12,e)}
 return forward(start.p,start.yaw,index==2 ? 0.25:5.0,e)
}
func fuelCruiser(_ e:Double,_ norfolk:Bool)->Pose {forward(norfolk ? pt(1550,-400):pt(1000,-1000),2.45,10,e)}
func fuelFleet(_ e:Double)->[FleetMember] {
 var result=denmarkActors.enumerated().map{FleetMember(id:$0.element.name,pose:fuelPose(e,$0.offset),scale:$0.element.scale,kind:$0.element.model.kind)}
 result += [FleetMember(id:"HMS SUFFOLK",pose:fuelCruiser(e,false),scale:0.58,kind:1),FleetMember(id:"HMS NORFOLK",pose:fuelCruiser(e,true),scale:0.58,kind:1)]
 return result
}
func fuelCamera(_ e:Double)->Cam {
 let p=fuelPose(e,0),target=fittedCamera(Cam(x:p.p.x,y:p.p.y,z:1.7),Array(fuelFleet(e).prefix(2)))
 return blendCamera(camera(3,36),target,smoother(e/10))
}
func drawFuelWorld(_ c:CGContext,_ e:Double,_ offset:Double=0){
 narrativeClock=108+e;explicitFuelOil=true;let cam=fuelCamera(e);beginWorld(c,cam,offset);ocean(c,108+e,false)
 for (i,a) in denmarkActors.enumerated() {let path:(Double)->Pose={fuelPose($0,i)},p=path(e)
  if i==2 {recordPresence(a.name,p,a.scale,a.model.kind);sinkingShip(c,a.model,p,a.scale,19+e,true);continue}
  if i==0 {oilSlick(c,{a.pose($0*30)},36+e/2.1,a.scale,24.6+e/2.1)}
  if i==3 {let clock=36+e*(12/10.5);smokeScreen(c,{a.pose($0*30)},clock,a.scale,clock-700/30)}
  vessel(c,a.model,path,e,a.scale,a.name,a.tint)
 }
 vessel(c,cruiserModel,{fuelCruiser($0,false)},e,0.58,"HMS SUFFOLK",blue)
 vessel(c,cruiserModel,{fuelCruiser($0,true)},e,0.58,"HMS NORFOLK",blue)
 explicitFuelOil=false;c.restoreGState()
}
func freeInset()->CGRect {
 let candidates=[CGRect(x:26,y:28,width:520,height:300),CGRect(x:734,y:28,width:520,height:300),CGRect(x:26,y:345,width:520,height:300),CGRect(x:734,y:345,width:520,height:300)]
 return candidates.min{a,b in bodyRects.filter{$0.intersects(a)}.count<bodyRects.filter{$0.intersects(b)}.count}!
}
func fuelSection(_ c:CGContext,_ e:Double){
 let enter=smoother((e-10)/1),exit=1-smoother((e-37)/1);if enter*exit<0.001{return}
 let r=freeInset();c.saveGState();c.clip(to:CGRect(x:r.minX,y:r.minY,width:r.width,height:r.height*enter));c.setAlpha(exit)
 c.setFillColor(ink.withAlphaComponent(0.96).cgColor);c.fill(r);c.translateBy(x:r.minX,y:r.minY)
 // Bow section: an AP shell passes through; water enters, and forward fuel is isolated.
 polygon(c,[pt(30,65),pt(460,65),pt(490,135),pt(490,255),pt(60,255),pt(30,215)],grey.withAlphaComponent(0.6))
 line(c,[pt(35,112),pt(477,112)],paper.withAlphaComponent(0.6),3)
 for x in [76.0,174,272] {polygon(c,[pt(x,155),pt(x+75,155),pt(x+75,239),pt(x,239)],gold.withAlphaComponent(0.42));line(c,[pt(x,148),pt(x,246)],grey,3)}
 let progress=smoother((e-12)/5),water=progress*92
 polygon(c,[pt(60,247-water),pt(348,247-water),pt(348,247),pt(60,247)],blue.withAlphaComponent(0.72))
 let shell=smoother((e-10.5)/2.3),x=mix(-25,540,shell)
 if shell<1 {polygon(c,[pt(x-12,181),pt(x,181),pt(x+4,184),pt(x,187),pt(x-12,187)],paper)}
 line(c,[pt(83,122),pt(83,142),pt(330,142),pt(330,165)],gold,3)
 let valve=smoother((e-18)/3)
 line(c,[pt(365,139),pt(392,139)],red,3);line(c,[pt(378.5,126),pt(378.5,152)],red,3)
 if valve>0 {line(c,[pt(363,124),pt(394,155)],red.withAlphaComponent(valve),2);line(c,[pt(394,124),pt(363,155)],red.withAlphaComponent(valve),2)}
 for j in 0..<20 {let phase=(e*0.35+Double(j)*0.21).truncatingRemainder(dividingBy:1),px=15-phase*50,py=185+sin(Double(j))*9;ellipse(c,px,py,5+phase*7,2+phase*3,NSColor.black.withAlphaComponent(0.35*progress*(1-phase)))}
 if e>25 {let q=smoother((e-25)/5);line(c,[pt(385,180),pt(466,180)],grey,4);polygon(c,[pt(385,185),pt(466,185),pt(466,239),pt(385,239)],blue.withAlphaComponent(0.6*q))}
 c.restoreGState()
}
func francePlan(_ c:CGContext,_ e:Double){
 let q=smoother((e-40)/2);if q<0.001{return}
 let r=freeInset(),cam=Cam(x:geo(-18,55.5).x,y:geo(-18,55.5).y,z:0.55),saved=annotationCamera
 c.saveGState();c.clip(to:CGRect(x:r.minX,y:r.minY,width:r.width,height:r.height*q));c.setFillColor(ink.cgColor);c.fill(r)
 c.translateBy(x:r.midX,y:r.midY);c.scaleBy(x:cam.z,y:cam.z);c.translateBy(x:-cam.x,y:-cam.y);annotationCamera=cam;ocean(c,e);chart(c)
 let a=geo(-31.8,63.3),b=geo(-38,56),d=geo(-2.4,47.3),control=geo(-26,48),progress=smoother((e-42)/10)
 var route:[CGPoint]=[];for i in 0...100 {route.append(bezier(a,b,control,d,progress*Double(i)/100))}
 c.saveGState();c.setLineDash(phase:0,lengths:[3,3]);line(c,route,gold,1.5);c.restoreGState()
 let p=bezier(a,b,control,d,progress),prev=bezier(a,b,control,d,max(0,progress-0.01)),angle=atan2(Double(p.y-prev.y),Double(p.x-prev.x))
 c.saveGState();c.translateBy(x:p.x,y:p.y);c.rotate(by:angle);polygon(c,[pt(7,0),pt(-5,-4),pt(-5,4)],gold);c.restoreGState();ellipse(c,d.x,d.y,4,4,blue)
 annotationCamera=saved;c.restoreGState()
}
func bowHitLens(_ c:CGContext,_ t:Double){
 let e=t-72;if e<6.3 || e>9.4{return}
 let alpha=smoother((e-6.3)/0.5)*(1-smoother((e-8.9)/0.5)),sim=denmarkTime(e),a=denmarkActors[3],b=denmarkActors[0],future=b.pose(342),target=worldPoint(pt(102,-2),future,b.scale),originPose=a.pose(310)
 let bearing=atan2(Double(target.y-originPose.p.y),Double(target.x-originPose.p.x)),origin=worldPoint(muzzleLocal(3,72,-3,bearing-originPose.yaw),originPose,a.scale),q=max(0,min(1,(sim-310)/32))
 let p=q<1 ? pt(mix(origin.x,target.x,q),mix(origin.y,target.y,q)):worldPoint(pt(102,-2),b.pose(sim),b.scale)
 c.saveGState();c.setAlpha(alpha);c.clip(to:CGRect(x:25,y:24,width:520,height:300));c.setFillColor(ink.cgColor);c.fill(CGRect(x:25,y:24,width:520,height:300));c.translateBy(x:285,y:174);c.scaleBy(x:3,y:3);c.translateBy(x:-p.x,y:-p.y)
 let saved=annotationCamera;annotationCamera=Cam(x:p.x,y:p.y,z:3);ocean(c,t);denmark(c,t,min(17,Int(t/6)),e/36);annotationCamera=saved
 if q<1 {c.saveGState();c.translateBy(x:p.x,y:p.y);c.rotate(by:bearing);polygon(c,[pt(-3,-0.5),pt(1,-0.5),pt(2,0),pt(1,0.5),pt(-3,0.5)],grey);c.restoreGState()};c.restoreGState()
}
// The Victorious hit remains on the same simulation clock as the fleet map.
// This live enlargement makes the carried weapon, hull contact and continued way visible.
func nightStrikeLens(_ c:CGContext,_ e:Double){
 if e<8.5 || e>17.5 || presenceAuditOnly{return}
 let alpha=smoother((e-8.5)/0.65)*(1-smoother((e-16.7)/0.8))
 let run=nightRuns[0],hit=nightContacts[0]!,b=chaseBismarck(e),plane=nightPlanePose(e,0)
 let local=hullLocal(hit.point,chaseBismarck(hit.time),0.85)
 let scar=worldPoint(local,b,0.85),tip=run.position(min(e,hit.time))
 let follow=smoother((e-hit.time)/1.3)
 let subject=e<run.release ? plane.p:pt(mix(tip.x,scar.x,follow),mix(tip.y,scar.y,follow))
 let centre=pt(mix(subject.x,b.p.x,0.63),mix(subject.y,b.p.y,0.63))
 let range=hypot(subject.x-b.p.x,subject.y-b.p.y)
 let r=CGRect(x:26,y:28,width:620,height:365)
 let hull=shipOutlines[0].map{worldPoint($0,b,0.85)}
 let extentX=hull.map{abs($0.x-centre.x)}.max()!,extentY=hull.map{abs($0.y-centre.y)}.max()!
 let base=min(2.05,480/max(245,range+150)),zx=292/max(1,extentX),zy=164.5/max(1,extentY)
 let zoom=pow(pow(base,-8)+pow(zx,-8)+pow(zy,-8),-1.0/8)
 c.saveGState();c.setAlpha(alpha);c.clip(to:r);c.setFillColor(ink.cgColor);c.fill(r)
 c.translateBy(x:r.midX,y:r.midY);c.scaleBy(x:zoom,y:zoom);c.translateBy(x:-centre.x,y:-centre.y)
 let saved=annotationCamera;annotationCamera=Cam(x:centre.x,y:centre.y,z:zoom)
 ocean(c,108+e,true)
 vessel(c,shipModel,chaseBismarck,e,0.85,"BISMARCK",red)
 // Reuse the actual aircraft and swept torpedo contact; there is no second staged hit.
 victoriousScene(c,e)
 if e>=hit.time {let age=e-hit.time
  c.saveGState();c.translateBy(x:scar.x,y:scar.y);c.rotate(by:b.yaw)
  puff(c,0,0,6,2.5,NSColor.black,0.5*smoother(age/0.35));c.restoreGState()
  // Brief shock flash at the waterline, followed by the existing persistent spray and foam.
  if age<0.22 {puff(c,hit.point.x,hit.point.y,10,6,gold,0.8*(1-age/0.22))}
 }
 annotationCamera=saved;c.restoreGState()
 c.saveGState();c.setAlpha(alpha);c.setStrokeColor(paper.withAlphaComponent(0.3).cgColor);c.setLineWidth(1);c.stroke(r);c.restoreGState()
}
var lastFinalNameTime = -100.0
func finalShipNames(_ c:CGContext,_ e:Double){
 if abs(e-lastFinalNameTime)>0.2 {labelHistory=[:]};lastFinalNameTime=e
 let fleet=sceneFleet(8,e),cam=camera(8,e);annotationCamera=cam;annotationOffset=0
 var occupied:[CGRect]=[]
 let bodies=fleet.map{ship -> CGRect in let corners=ship.corners.map{screen($0)},xs=corners.map{$0.x},ys=corners.map{$0.y};return CGRect(x:xs.min()!,y:ys.min()!,width:xs.max()!-xs.min()!,height:ys.max()!-ys.min()!).insetBy(dx:-7,dy:-7)}
 let alpha=smoother(e/0.8)
 c.saveGState();c.setAlpha(alpha)
 for item in fleet {let raw=screen(item.pose.p),outside=raw.x<25 || raw.x>1255 || raw.y<30 || raw.y>650
  let anchor=pt(max(25,min(1255,raw.x)),max(32,min(646,raw.y)))
  let name=(item.id=="RODNEY" || item.id=="KING GEORGE V" ? "HMS ":"")+item.id+(outside && e>36 ? " · retiring":"")
  let width=min(240,Double(name.count)*7.6+14),height=24.0
  let hull=item.corners.map{screen($0)},left=hull.map{$0.x}.min()!,right=hull.map{$0.x}.max()!,top=hull.map{$0.y}.min()!,bottom=hull.map{$0.y}.max()!
  let candidates=[pt(right+13,top-12),pt(left-width-13,bottom-12),pt((left+right-width)/2,top-36),pt((left+right-width)/2,bottom+12),pt(anchor.x+15,anchor.y+32),pt(anchor.x-width-15,anchor.y-48),pt(anchor.x-width/2,anchor.y+65),pt(anchor.x-width/2,anchor.y-82)]
  var chosen=CGRect(x:30,y:40+Double(occupied.count)*32,width:width,height:height)
  for p in candidates {let r=CGRect(x:max(25,min(1255-width,p.x)),y:max(28,min(642,p.y)),width:width,height:height)
   if !occupied.contains(where:{$0.insetBy(dx:-5,dy:-4).intersects(r)}) && !bodies.contains(where:{$0.intersects(r)}) {chosen=r;break}
  }
  let key="final:"+item.id
  if let old=labelHistory[key] {chosen.origin.x=mix(old.origin.x,chosen.origin.x,0.18);chosen.origin.y=mix(old.origin.y,chosen.origin.y,0.18)}
  labelHistory[key]=chosen;occupied.append(chosen)
  let end=pt(chosen.midX,chosen.midY<anchor.y ? chosen.maxY:chosen.minY),color=item.id=="BISMARCK" ? red:paper
  line(c,[anchor,end],color.withAlphaComponent(0.6),0.7)
  c.setFillColor(ink.withAlphaComponent(0.86).cgColor);c.fill(chosen)
  txt(name,chosen.minX+6,chosen.minY+3,13,color,true,width-10)
  if outside {ellipse(c,anchor.x,anchor.y,2,2,blue)}
 }
 c.restoreGState()
}
func filmCueList()->[(Double,String)] {
 var cues=scriptCues.filter{$0.0<72}
 cues += [(72,"British intercept force · from Scapa Flow"),(86,"Hood leads · Prince of Wales follows toward Iceland"),(96,"Prinz Eugen moves into the German lead"),(100,"02:05 · Holland turns parallel, waiting for daylight"),(112,"03:40 · British force turns in at 28 knots"),(122,"05:35 · enemy sighted; range closes"),(132,"05:52 · Hood and Prince of Wales open fire"),(138,"Hood initially targets Prinz Eugen · Prince of Wales targets Bismarck"),(142,"German ships reply · ranging salvos"),(148,"Prince of Wales hits Bismarck's bow"),(153.5,"Another hit · flooding below the armour belt"),(156,"Bismarck · decisive salvo toward Hood"),(164,"Shell penetration · probable aft-magazine ignition"),(166,"Hood · aft-magazine explosion"),(176,"Hood sinks · Prince of Wales remains under fire"),(179,"Prince of Wales returns fire at Bismarck"),(184,"Bismarck shifts fire · Prince of Wales prepares to withdraw"),(186,"Bridge damage · Prince of Wales turns away under smoke"),(204,"Bismarck survives the action · fuel leaks astern"),(214,"Bow damage · schematic reconstruction"),(222,"Seawater enters · forward fuel tanks become unusable"),(230,"Further flooding · speed and endurance reduced"),(242,"Atlantic raiding abandoned · make for a French repair port")]
 cues += scriptCues.filter{$0.0>=108 && $0.0<240 && $0.0 != 120 && $0.0 != 123}.map{($0.0+150,$0.1)}
 cues += [(327,"Bismarck AA batteries engage the Swordfish"),(267,"Victorious · Swordfish torpedo attack"),(270,"Torpedo hits Bismarck amidships · main armour belt"),(273,"Belt resists penetration · Bismarck continues underway"),(275,"25 May · HMS Suffolk + HMS Norfolk zigzag")]
 cues += [(390,"27 May · final action · north up / enlarged ship symbols"),(392,"08:47 · HMS Rodney opens fire"),(393,"08:48 · HMS King George V opens fire; HMS Norfolk joins"),(398,"HMS Dorsetshire engages from the opposite side"),(406,"09:20 · battleships turn north on independent tracks"),(420,"Close-range bombardment · Bismarck loses effective fire"),(424,"HMS Rodney + HMS King George V begin retiring"),(426,"10:21 · battleship gunfire ends"),(429,"HMS Dorsetshire · two torpedoes against the starboard side"),(434,"Dorsetshire rounds the bow · final port-side torpedo"),(435,"Bismarck capsizes · British ships remain afloat")]
 return cues.sorted{$0.0<$1.0}
}
let filmCues=filmCueList()
func designFrame(_ c:CGContext,_ draw:()->Void){
 c.saveGState();c.translateBy(x:0,y:Double(H));c.scaleBy(x:1.5,y:-1.5);NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=NSGraphicsContext(cgContext:c,flipped:true);draw();NSGraphicsContext.restoreGraphicsState();c.restoreGState()
}
func render(_ t:Double,_ c:CGContext){
 environmentClock=t;suppressScriptCues=true
 if t<72 {renderBase(t,c)}
 else if t<132 {designFrame(c){annotations=[];bodyRects=[];drawLongApproach(c,t-72)}}
 else if t<204 {renderBase(72+(t-132)/2,c)}
 else if t<258 {designFrame(c){annotations=[];bodyRects=[];drawFuelWorld(c,t-204);fuelSection(c,t-204);francePlan(c,t-204)}}
 else {renderBase(t-150,c);if t>=266.5 && t<=275.5 {designFrame(c){nightStrikeLens(c,t-258)}}}
 suppressScriptCues=false
 if t<438,let cue=filmCues.last(where:{$0.0<=t}) {designFrame(c){suppressWorldText=false;let a=smoother((t-cue.0)/0.35);c.setAlpha(a);c.setFillColor(ink.withAlphaComponent(0.72).cgColor);c.fill(CGRect(x:22,y:670,width:min(1000,Double(cue.1.count)*8.4+24),height:30));txt(cue.1,34,674,15,paper,false,1150)}}
 environmentClock=nil
}

func fleetOverlaps(_ a:FleetMember,_ b:FleetMember)->Bool {
 let p=a.corners,q=b.corners
 for poly in [p,q] {for i in poly.indices {let u=poly[i],v=poly[(i+1)%poly.count],nx=Double(v.y-u.y),ny=Double(u.x-v.x)
  if abs(nx)+abs(ny)<1e-9 {continue}
  let ap=p.map{Double($0.x)*nx+Double($0.y)*ny},bp=q.map{Double($0.x)*nx+Double($0.y)*ny}
  if ap.max()!<bp.min()! || bp.max()!<ap.min()! {return false}
 }}
 return true
}
func finalActionAudit(){
 var overlaps=0,framing=0,maxSlip=0.0
 for frame in 0...1152 {let e=Double(frame)/24,fleet=sceneFleet(8,e),cam=camera(8,e)
  precondition(Set(fleet.map{$0.id})==Set(finalActors.map{$0.name}),"Final ship membership changed")
  for a in 0..<fleet.count {for b in (a+1)..<fleet.count {if fleetOverlaps(fleet[a],fleet[b]){if overlaps<12 {print("FINAL OVERLAP t=\(e) \(fleet[a].id)/\(fleet[b].id)")};overlaps+=1}}}
  if e<36 {for ship in fleet {for p in ship.corners {let x=640+(p.x-cam.x)*cam.z,y=355+(p.y-cam.y)*cam.z;if x<15 || x>1265 || y<15 || y>665 {framing+=1;break}}}}
  for i in 0..<5 {let p=finalTrackPose(i,e),a=finalTrackPose(i,e-0.001),b=finalTrackPose(i,e+0.001),dx=b.p.x-a.p.x,dy=b.p.y-a.p.y;maxSlip=max(maxSlip,abs(sin(p.yaw)*dx-cos(p.yaw)*dy)/max(1e-8,hypot(dx,dy)))}
 }
 print("FINAL FLEET: overlaps=\(overlaps), early cropped hulls=\(framing), max sideslip=\(maxSlip)");fflush(stdout)
 precondition(overlaps==0 && framing==0 && maxSlip<0.005)
 let b=finalTrackPose(0,0).p,r=finalTrackPose(1,0).p,k=finalTrackPose(2,0).p,n=finalTrackPose(3,0).p,d=finalTrackPose(4,0).p
 precondition(r.x<b.x && r.y<b.y && k.x<b.x && k.y<b.y && r.y<k.y && n.y<b.y && d.x>b.x && d.y>b.y,"Opening relative stations")
 for i in 1...2 {let a=finalTrackPose(i,40).p,b=finalTrackPose(i,47).p;precondition(b.y<a.y && b.x>=a.x,"Battleships must retire north-east")}
 for i in 0..<3 {let hit=finalContacts[i]!;let local=hullLocal(hit.point,finalTrackPose(0,hit.time),0.33)
  print("DORSETSHIRE TORPEDO \(i+1): impact e=\(hit.time), local=\(local)")
  precondition(i<2 ? local.y>0:local.y<0,"Torpedo hit wrong side")
 }
 print("HISTORICAL STAGING PASS: north-up WNW approach; separated battleships; flank cruisers; battleship retirement; two starboard and one port Dorsetshire runs. Positions between selected chart/report stations are illustrative.")
}

func longEditAudit(){
 print("Building coastline query index");fflush(stdout)
 var rows:[Int:[(CGPoint,CGPoint)]]=[:]
 func edge(_ a:CGPoint,_ b:CGPoint){let lo=Int(floor(min(a.y,b.y)/2)),hi=Int(floor(max(a.y,b.y)/2));if lo<=hi {for row in lo...hi {rows[row,default:[]].append((a,b))}}}
 for path in landPaths {var first=CGPoint.zero,last=CGPoint.zero
  path.applyWithBlock{pointer in let e=pointer.pointee
   switch e.type {
   case .moveToPoint:first=e.points[0];last=first
   case .addLineToPoint:let p=e.points[0];edge(last,p);last=p
   case .closeSubpath:edge(last,first);last=first
   default:break
   }
  }
 }
 func onLand(_ p:CGPoint)->Bool {var inside=false
  for (a,b) in rows[Int(floor(p.y/2))] ?? [] {if (a.y>p.y) != (b.y>p.y) && p.x<(b.x-a.x)*(p.y-a.y)/(b.y-a.y)+a.x {inside.toggle()}}
  return inside
 }
 var overlap=0,shore=0,framing=0,maxSideSlip=0.0
 for i in 0...240 {let t=Double(i)/4,fleet=approachFleet(t),cam=longApproachCamera(t)
  for a in 0..<fleet.count {for b in (a+1)..<fleet.count {if fleetOverlaps(fleet[a],fleet[b]){if overlap<12{print("APPROACH OVERLAP t=\(t) \(fleet[a].id)/\(fleet[b].id)")};overlap+=1}}}
  for ship in fleet {if ship.corners.contains(where:{onLand($0)}) {if shore<12{print("LAND t=\(t) \(ship.id), pose=\(ship.pose.p)")};shore+=1}}
  if t>=8 {for ship in fleet.prefix(4) {for p in ship.corners {let dx=p.x-cam.x,dy=p.y-cam.y,x=640+(dx*cos(cam.angle)-dy*sin(cam.angle))*cam.z,y=355+(dx*sin(cam.angle)+dy*cos(cam.angle))*cam.z
   if x<15 || x>1265 || y<15 || y>665 {if framing<10{print("CROP t=\(t) \(ship.id), \(x),\(y)")};framing+=1;break}
  }}}
  let paths:[(Double)->Pose]=[{approachingGerman($0)},{approachingGerman($0,true)},{approachingHood($0)},{approachingHood($0,true)}]
  for path in paths {let p=path(t),a=path(t-0.001),b=path(t+0.001),dx=b.p.x-a.p.x,dy=b.p.y-a.p.y,speed=hypot(dx,dy)
   if speed>1e-8 {let error=abs(sin(p.yaw)*dx-cos(p.yaw)*dy)/speed;maxSideSlip=max(maxSideSlip,error)}
  }
 }
 print("APPROACH: overlaps=\(overlap), shore intersections=\(shore), cropped hulls=\(framing), maximum sideslip=\(maxSideSlip)");fflush(stdout)
 precondition(overlap==0 && shore==0 && framing==0 && maxSideSlip<0.03,"Approach staging check failed")
 func project(_ p:CGPoint,_ cam:Cam)->CGPoint {let x=p.x-cam.x,y=p.y-cam.y;return pt(640+(x*cos(cam.angle)-y*sin(cam.angle))*cam.z,355+(x*sin(cam.angle)+y*cos(cam.angle))*cam.z)}
 let last=approachFleet(60),a=longApproachCamera(60),b=camera(3,0)
 for (i,s) in last.prefix(4).enumerated() {let actor=denmarkActors[i],aa=project(s.pose.p,a),bb=project(actor.position(0),b),error=hypot(aa.x-bb.x,aa.y-bb.y)
  print("BATTLE HANDOFF \(s.id): centre error \(error) px")
  precondition(error<1 && abs(s.scale*a.z-actor.scale*b.z)<0.005,"Battle handoff discontinuity")
 }
 for i in 0...108 {let t=Double(i)/2,fleet=fuelFleet(t)
  for a in 0..<fleet.count {if fleet[a].id=="HOOD"{continue};for b in (a+1)..<fleet.count {if fleet[b].id=="HOOD"{continue};precondition(!fleetOverlaps(fleet[a],fleet[b]),"Fuel scene hull overlap")}}
 }
 let fuel0=fuelFleet(0),end=denmarkActors.map{$0.pose(1080)}
 for i in 0..<4 {precondition(hypot(fuel0[i].pose.p.x-end[i].p.x,fuel0[i].pose.p.y-end[i].p.y)<1e-7)}
 print("FUEL CHECK PASS: bow and below-belt hits, inherited oil trail, continuous surviving ships");fflush(stdout)
 let ctx=CGContext(data:nil,width:1,height:1,bitsPerComponent:8,bytesPerRow:4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
 NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=NSGraphicsContext(cgContext:ctx,flipped:true);presenceAuditOnly=true
 let registry=["BISMARCK","PRINZ EUGEN","HOOD","PRINCE OF WALES","HMS SUFFOLK","HMS NORFOLK","HMS VICTORIOUS","HMS ARK ROYAL","HMS SHEFFIELD","RODNEY","KING GEORGE V","HMS DORSETSHIRE"]+destroyerNames
 var csv="film_seconds,scene,ship,state,x,y,heading,scale,coordinate_system\n",samples=0
 for frame in 12..<876 {let t=Double(frame)/2;presenceRecords=[];annotations=[];bodyRects=[];environmentClock=t
  let cam:Cam,scene:String,coordinate:String
  if t>=72 && t<132 {cam=longApproachCamera(t-72);scene="British approach";coordinate="geographic_projection";drawLongApproach(ctx,t-72)}
  else if t>=204 && t<258 {cam=fuelCamera(t-204);scene="Fuel damage";coordinate="tactical_diagram";drawFuelWorld(ctx,t-204)}
  else {let story=t<72 ? t:t<204 ? 72+(t-132)/2:t-150,g=groupAt(story);cam=camera(g,story-groups[g]);scene="\(g)";coordinate=[1,2,4,10].contains(g) ? "geographic_projection":"tactical_diagram";narrativeClock=story;drawWorld(ctx,g,story)}
  for id in registry {if let ship=presenceRecords.first(where:{$0.id==id}) {let points=ship.corners.map{project($0,cam)},visible=points.contains{$0.x>=0 && $0.x<=1280 && $0.y>=0 && $0.y<=720},sunk=(id=="HOOD" && t>=182)||(id=="BISMARCK" && t>=437.5)
   csv += "\(t),\(scene),\(id),\(sunk ? "sunk":visible ? "in_frame":"offscreen"),\(ship.pose.p.x),\(ship.pose.p.y),\(ship.pose.yaw),\(ship.scale),\(coordinate)\n"
  }else{csv += "\(t),\(scene),\(id),\(id=="HOOD" && t>=182 ? "sunk":"other_location"),,,,,\n"}}
  samples+=1
 }
 presenceAuditOnly=false;environmentClock=nil;explicitFuelOil=false;NSGraphicsContext.restoreGraphicsState()
 try! csv.write(to:root.appendingPathComponent("ship-state-ledger.csv"),atomically:true,encoding:.utf8)
 print("EXTENDED LEDGER PASS: \(samples) sampled frames, 17 persistent ship identities, 450-second film")
}

func continuityAudit(){
 var minPlaneGap=Double.infinity,maxJump=0.0,flightSamples=0,closestTime=0.0,closestPair=""
 for i in 0...3456 {let t=Double(i)/48
  let p=(0..<3).map{swordfishPose(t,$0)}
  for a in 0..<3 {for b in (a+1)..<3 {let d=hypot(p[a].p.x-p[b].p.x,p[a].p.y-p[b].p.y);if d<minPlaneGap{minPlaneGap=d;closestTime=t;closestPair="\(a),\(b)"}}}
  for n in 0..<3 {let before=swordfishPose(t-0.001,n),after=swordfishPose(t+0.001,n);maxJump=max(maxJump,hypot(after.p.x-before.p.x,after.p.y-before.p.y));flightSamples+=1}
 }
 print("FLIGHT CHECK: closest pair \(closestPair) at \(closestTime); minimum aircraft centre separation \(minPlaneGap), maximum 2ms displacement \(maxJump), \(flightSamples) samples");fflush(stdout)
 precondition(minPlaneGap>17,"Aircraft overlap in plan view")
 for n in 0..<3 {
  let p=attackPlane(runs[n].release,n),nose=forward(p.p,p.yaw,1,3.42).p,torp=runs[n].position(runs[n].release)
  precondition(hypot(nose.x-torp.x,nose.y-torp.y)<0.01,"Torpedo does not continue from carried position")
 }
 for n in 1..<3 {var hit=false
  let run=wrongRuns[n]
  for i in 0...2400 {let t=run.release+0.65+Double(i)/240
   if insideHull(run.position(t),sheffieldPose(t),0.42,1){hit=true;print("WRONG-STRIKE CONTACT: run \(n), t \(t)");break}
  }
  precondition(!hit,"Sheffield must evade the running torpedoes")
 }
 print("TORPEDO CHECK PASS: carried-release continuity and Sheffield evasion");fflush(stdout)
 var overlapCount=0
 for g in [3,4,5,6,7,8] {let duration=groupEnd(g)-groups[g]
  for i in 0...Int(duration*2) {let e=Double(i)/2,members=sceneFleet(g,e)
   for a in 0..<members.count {for b in (a+1)..<members.count {if fleetOverlaps(members[a],members[b]){if overlapCount<12{print("FLEET OVERLAP: scene \(g), elapsed \(e), \(members[a].id) / \(members[b].id)")};overlapCount+=1}}}
  }
 }
 print("FLEET OVERLAP COUNT: \(overlapCount)");fflush(stdout)
 precondition(overlapCount==0,"Ships overlap during manoeuvres")
 // Both vessels must remain wholly inside the frame throughout departure and inspection.
 for i in 0..<1296 {let t=6+Double(i)/24,g=groupAt(t),e=t-groups[g],cam=camera(g,e)
  for ship in sceneFleet(g,e){for p in ship.corners {let x=Double(p.x)-cam.x,y=Double(p.y)-cam.y,sx=640+(x*cos(cam.angle)-y*sin(cam.angle))*cam.z,sy=355+(x*sin(cam.angle)+y*cos(cam.angle))*cam.z
   precondition(sx>=20 && sx<=1260 && sy>=20 && sy<=665,"Opening ship cropped: \(ship.id), t \(t), \(sx),\(sy)")
  }}
 }
 // The geographic carrier and tactical close-up must share a screen position and orientation at the handoff.
 let a=camera(4,36),b=camera(5,0),p=searchArkPose(36),q=carrierPose(0)
 func project(_ p:CGPoint,_ cam:Cam)->CGPoint {let x=p.x-cam.x,y=p.y-cam.y;return pt(640+(x*cos(cam.angle)-y*sin(cam.angle))*cam.z,355+(x*sin(cam.angle)+y*cos(cam.angle))*cam.z)}
 let pa=project(p.p,a),pb=project(q.p,b)
 precondition(hypot(pa.x-pb.x,pa.y-pb.y)<0.01,"Carrier zoom position mismatch")
 precondition(abs(sin(p.yaw+a.angle-q.yaw-b.angle))<1e-6,"Carrier zoom orientation mismatch")
 let c=camera(5,24),d=camera(6,0)
 precondition(hypot(c.x-d.x,c.y-d.y)<1e-6 && abs(c.z-d.z)<1e-6,"Camera jumps after second launch")
 print("FRAMING CHECK PASS: paired opening, carrier match zoom, continuous second-strike camera");fflush(stdout)
 // Audit actual draw calls: no member is gated on/off within its local scene.
 let ctx=CGContext(data:nil,width:1,height:1,bitsPerComponent:8,bytesPerRow:4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
 NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=NSGraphicsContext(cgContext:ctx,flipped:true)
 presenceAuditOnly=true
 var csv="film_seconds,scene,ship,state,x,y,heading,scale,coordinate_system\n",checks=0
 let registry=["BISMARCK","PRINZ EUGEN","HOOD","PRINCE OF WALES","HMS SUFFOLK","HMS NORFOLK","HMS VICTORIOUS","HMS ARK ROYAL","HMS SHEFFIELD","RODNEY","KING GEORGE V","HMS DORSETSHIRE"]+destroyerNames
 for g in groupOrder.dropFirst().dropLast() {
  let start=groups[g],end=groupEnd(g);var expected:Set<String>?=nil
  for frame in 0..<Int((end-start)*2) {let t=start+Double(frame)/2
   presenceRecords=[];annotations=[];bodyRects=[];annotationTime=t;annotationGroup=g
   drawWorld(ctx,g,t)
   let ids=Set(presenceRecords.map{$0.id})
   if expected==nil{expected=ids};precondition(ids==expected!,"Ships switched on or off inside scene \(g), t \(t): \(ids)")
   for id in registry {
    if let s=presenceRecords.first(where:{$0.id==id}) {let cam=camera(g,t-start),pts=s.corners.map{project($0,cam)},visible=pts.contains{$0.x>=0 && $0.x<=1280 && $0.y>=0 && $0.y<=720}
     let sunk=(id=="HOOD" && t>=97)||(id=="BISMARCK" && t>=287.5)
     csv += "\(t),\(g),\(id),\(sunk ? "sunk":visible ? "in_frame":"offscreen"),\(s.pose.p.x),\(s.pose.p.y),\(s.pose.yaw),\(s.scale),\(g==4 || g==1 || g==2 || g==10 ? "geographic_projection":"tactical_diagram")\n"
    }else{csv += "\(t),\(g),\(id),\(id=="HOOD" && t>=97 ? "sunk":"other_location"),,,,,\n"}
   };checks+=1
  }
 }
 presenceAuditOnly=false;suppressWorldText=false;NSGraphicsContext.restoreGraphicsState()
 try! csv.write(to:root.appendingPathComponent("ship-state-ledger.csv"),atomically:true,encoding:.utf8)
 print("PRESENCE CHECK PASS: \(checks) scene samples; constant ship membership per scene, including all British ships at Bismarck sinking")
 print("Entity ledger written: ship-state-ledger.csv");fflush(stdout)
}

func hullAudit(){
 let models=[0:shipModel,1:cruiserModel,2:rodneyModel,3:kgvModel,4:hoodModel,6:destroyerModel]
 let kinds=[0,1,2,3,4,6]
 let names=[0:"BISMARCK",1:"PRINZ EUGEN",2:"RODNEY",3:"KING GEORGE V",4:"HOOD",6:"DESTROYER"]
 var muzzleChecks=0,pixelChecks=0,maxFringe=0.0
 for kind in kinds {
  let locations:[Double]=kind==2 ? [76,45,12]:kind==3 ? [72,46,-85]:[72,46,-61,-91]
  for degrees in 0..<360 {
   let angle=Double(degrees)*Double.pi/180
   for (j,tx) in locations.enumerated(){
    let barrels:[Double]=kind==2 ? [-3,0,3]:kind==3 && j != 1 ? [-3,-1,1,3]:[-2.4,2.4]
    for yy in barrels {
     let p=muzzleLocal(kind,tx,yy,angle)
     precondition(shipHullPaths[kind].contains(p),"Muzzle outside hull: \(names[kind]!), \(degrees)°")
     muzzleChecks+=1
    }
    for n in 0..<36 {let a=Double(n)*Double.pi/18,scale=classScale(kind)
     precondition(shipHullPaths[kind].contains(pt((tx+cos(a)*8.2)*scale.x,sin(a)*8.2*scale.y)),"Turret mount outside hull")
    }
   }
  }
  for degrees in stride(from:0,through:345,by:15) {
   let w=800,h=240
   let ctx=CGContext(data:nil,width:w,height:h,bitsPerComponent:8,bytesPerRow:w*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
   ctx.translateBy(x:400,y:120);ctx.scaleBy(x:2.5,y:2.5)
   aimWorld=Double(degrees)*Double.pi/180
   ship(ctx,models[kind]!,0,0,1,0,Double.pi/2,0,false)
   let bytes=ctx.data!.assumingMemoryBound(to:UInt8.self)
   for y in 0..<h {for x in 0..<w {
    if bytes[(y*w+x)*4+3]<16 {continue}
    pixelChecks+=1
    let p=pt((Double(x)+0.5-400)/2.5,(Double(y)+0.5-120)/2.5)
    if shipHullPaths[kind].contains(p){continue}
    var distance=Double.infinity;let hull=shipOutlines[kind]
    for i in hull.indices {let a=hull[i],b=hull[(i+1)%hull.count],dx=b.x-a.x,dy=b.y-a.y,den=dx*dx+dy*dy
     if den<1e-16 {continue}
     let u=max(0,min(1,((p.x-a.x)*dx+(p.y-a.y)*dy)/den))
     distance=min(distance,hypot(Double(p.x-a.x-u*dx),Double(p.y-a.y-u*dy)))
    }
    maxFringe=max(maxFringe,distance)
    precondition(distance<0.35,"Sprite pixels outside hull: \(names[kind]!), \(degrees)°, \(p), distance \(distance)")
   }}
  }
 }
 aimWorld=nil
 let carrier=outlinePath(carrierHull)
 for p in carrierIsland {precondition(carrier.contains(p),"Carrier island outside deck")}
 for n in 0..<3 {let x=20-Double(n)*22
  for dx in [-34.0,38] {for dy in [-43.0,43] {precondition(carrier.contains(pt((x+dx*0.18)/0.33,dy*0.18/0.33)),"Parked aircraft over carrier deck edge")}}
 }
 print("CARRIER AUDIT PASS: Ark Royal island and all three representative parked aircraft footprints inside deck")
 print("HULL AUDIT PASS: all 6 ship plan types; \(muzzleChecks) muzzle positions across 360°; turret mounts contained")
 print("RASTER AUDIT PASS: \(pixelChecks) visible pixels across 144 ship/bearing combinations; maximum antialias fringe \(maxFringe) drawing units")
 // A native contact sheet shows each class fore-and-aft, oblique and broadside.
 let ctx=CGContext(data:nil,width:1920,height:1080,bitsPerComponent:8,bytesPerRow:1920*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
 ctx.translateBy(x:0,y:1080);ctx.scaleBy(x:1.5,y:-1.5)
 NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=NSGraphicsContext(cgContext:ctx,flipped:true)
 ctx.setFillColor(ink.cgColor);ctx.fill(CGRect(x:0,y:0,width:1280,height:720))
 txt("HULL FIT / ALL SIX SHIP PLAN TYPES",35,18,23,gold,true)
 for (col,bearing) in [0.0,45,90].enumerated(){txt("GUN BEARING \(Int(bearing))°",55+Double(col)*420,58,15,paper,true)}
 for (row,kind) in kinds.enumerated() {let y=135.0+Double(row)*102
  txt(names[kind]!,35,y-40,14,gold,true)
  for (col,bearing) in [0.0,45,90].enumerated(){aimWorld=bearing*Double.pi/180;ship(ctx,models[kind]!,220+Double(col)*420,y,1.25,0,Double.pi/2,0,false)}
 }
 aimWorld=nil;NSGraphicsContext.restoreGraphicsState()
 let rep=NSBitmapImageRep(cgImage:ctx.makeImage()!);try! rep.representation(using:.png,properties:[:])!.write(to:root.appendingPathComponent("hull-fit-review.png"))
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
 let previous=bismarckAttackPath(48),following=damagedShip(0)
 precondition(hypot(Double(previous.p.x-following.p.x),Double(previous.p.y-following.p.y))<1e-8)
 let a=bismarckAttackPath(47.999),b=damagedShip(0.001)
 precondition(abs(hypot(Double(previous.p.x-a.p.x),Double(previous.p.y-a.p.y))/0.001-hypot(Double(b.p.x-following.p.x),Double(b.p.y-following.p.y))/0.001)<0.01,"Speed jump at steering damage")
 let release=attackPlane(runs[2].release,2),torpA=torpedoPosition(runs[2].release),torpB=torpedoPosition(runs[2].release+0.01)
 let tx=Double(torpB.x-torpA.x),ty=Double(torpB.y-torpA.y)
 precondition((cos(release.yaw)*tx+sin(release.yaw)*ty)/hypot(tx,ty)>0.999,"Torpedo reverses at release")
 for n in 0..<3 {if let hit=contacts[n] {let local=hullLocal(hit.point,bismarckAttackPath(hit.time),1.05);print("TORPEDO \(n+1): contact \(hit.time), hull-local \(local)") }else {print("TORPEDO \(n+1): miss")}}
 precondition(contacts[0] != nil && contacts[1] == nil && contacts[2] != nil)
 precondition(hullLocal(contacts[2]!.point,bismarckAttackPath(contacts[2]!.time),1.05).x < -100)
 for i in 0...600 {let t=Double(i)/20
  for escort in [false,true] {let p=departurePose(t,escort)
   for v in collisionHulls[escort ? 1:0] {let q=worldPoint(v,p,0.012);precondition(!landPaths.contains(where:{$0.contains(q,using:.evenOdd)}),"Departure hull on land at \(t), escort \(escort)")}
  }
  if t>0 && t<29.9 {let a=departurePose(t-0.001),b=departurePose(t+0.001),c=departurePose(t-0.001,true),d=departurePose(t+0.001,true);precondition(abs(hypot(b.p.x-a.p.x,b.p.y-a.p.y)-hypot(d.p.x-c.p.x,d.p.y-c.p.y))<0.0001)}
 }
 for e in [5.5,8.0,12,20] {precondition(abs(sin(departurePose(30+e).yaw+camera(1,e).angle))<0.000001)}
 print("OPENING AUDIT PASS: offshore hulls, equal formation speed, horizontal specification view")
 print("MOTION AUDIT PASS: \(total) sampled poses, maximum sideslip ratio \(maxError); forward torpedo release")
 // Camera curves must be position-continuous across all internal keyframes.
 for group in [3,4,5,8,9] {for k in cameraKeys[group].dropFirst().dropLast(){let a=camera(group,k.t-0.0001),b=camera(group,k.t+0.0001);precondition(hypot(a.x-b.x,a.y-b.y)<0.1 && abs(a.z-b.z)<0.01)}}
 for group in [3,4,5,8,9] {for k in cameraKeys[group].dropFirst().dropLast(){let dt=0.0001,a=camera(group,k.t-dt),b=camera(group,k.t),c=camera(group,k.t+dt)
  precondition(abs((b.x-a.x)/dt-(c.x-b.x)/dt)<0.1 && abs((b.y-a.y)/dt-(c.y-b.y)/dt)<0.1,"Camera speed jump")
  precondition(abs((b.z-a.z)/dt-(c.z-b.z)/dt)<0.001)
 }}
 print("CAMERA AUDIT PASS: continuous position, speed and acceleration; no per-caption reset")
}
let pixels=UnsafeMutableRawPointer.allocate(byteCount:W*H*4,alignment:64)
let context=CGContext(data:pixels,width:W,height:H,bitsPerComponent:8,bytesPerRow:W*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.noneSkipFirst.rawValue)!
if CommandLine.arguments.contains("--export-cues") {
 var csv="film_seconds,timecode,script_cue\n"
 let cues=filmCues+[(438.0,"Fade to black"),(439.0,"Human cost · 2,000+ dead / ~100 survivors"),(444.0,"Operation Rheinübung · 18–27 May 1941")]
 for (t,label) in cues {let time=String(format:"%02d:%04.1f",Int(t)/60,t.truncatingRemainder(dividingBy:60)),quoted=label.replacingOccurrences(of:"\"",with:"\"\"");csv += "\(t),\(time),\"\(quoted)\"\n"}
 try! csv.write(to:root.appendingPathComponent("script-cues.csv"),atomically:true,encoding:.utf8);print("Script cues exported")
}
else if CommandLine.arguments.contains("--weapon-report") {
 for n in 0..<3 {print("FINAL STRIKE \(n+1): \(contacts[n]?.time.description ?? "miss")");print("VICTORIOUS \(n+1): \(nightContacts[n]?.time.description ?? "miss")");if let hit=nightContacts[n] {print("VICTORIOUS LOCAL CONTACT: \(hullLocal(hit.point,chaseBismarck(hit.time),0.85))")}}
}
else if CommandLine.arguments.contains("--final-audit") {finalActionAudit()}
else if CommandLine.arguments.contains("--long-audit") {longEditAudit()}
else if CommandLine.arguments.contains("--continuity-audit") {continuityAudit()}
else if CommandLine.arguments.contains("--hull-audit") {hullAudit()}
else if CommandLine.arguments.contains("--audit") {continuityAudit()}
else if CommandLine.arguments.contains("--stills") {
 for t in [390.5,394.0,400.0,406.0,414.0,424.0,429.3,431.0,434.4,436.5] {try autoreleasepool{render(t,context);let rep=NSBitmapImageRep(cgImage:context.makeImage()!);try rep.representation(using:.png,properties:[:])!.write(to:root.appendingPathComponent("shot-\(t).png"))}}
}else{
 let ffmpeg=CommandLine.arguments[2],preview=CommandLine.arguments.contains("--preview")
 let process=Process();process.executableURL=URL(fileURLWithPath:ffmpeg)
 let output=preview ? "motion-preview.mp4":"bismarck-silent.mp4"
 process.arguments=["-y","-v","error","-f","rawvideo","-pixel_format","argb","-video_size","1920x1080","-framerate","24","-i","pipe:0","-an","-c:v","libx264","-crf","17","-preset","fast","-pix_fmt","yuv420p","-movflags","+faststart",root.appendingPathComponent(output).path]
 let pipe=Pipe();process.standardInput=pipe;try process.run()
 let ranges:[Range<Int>]=preview ? [Int(65*fps)..<Int(260*fps)]:[0..<(duration*fps)]
 for range in ranges {for frame in range {autoreleasepool{render(Double(frame)/Double(fps),context);pipe.fileHandleForWriting.write(Data(bytesNoCopy:pixels,count:W*H*4,deallocator:.none))};if frame%720==0 {print("Rendered \(frame/fps)s");fflush(stdout)}}}
 try pipe.fileHandleForWriting.close();process.waitUntilExit();precondition(process.terminationStatus==0);print("VIDEO COMPLETE")
}
pixels.deallocate()
