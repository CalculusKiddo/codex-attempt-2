import AppKit
import AVFoundation

// A self-contained five-minute motion-graphics documentary template.
let root = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : FileManager.default.currentDirectoryPath)
let W = 1280, H = 720, fps = 12, length = 300
struct Chapter {
    let date: String, title: String, tag: String, cards: [String]
}
let chapters: [Chapter] = [
 .init(date:"MAY 1941", title:"The hunt for Bismarck", tag:"A NORTH ATLANTIC TIMELINE", cards:["One battleship. An ocean-wide pursuit.","Bismarck and Prinz Eugen set out to attack Allied shipping.","Follow the breakout, the chase, and the attack that changed its course."]),
 .init(date:"18–21 MAY", title:"Into the Atlantic", tag:"01 / THE BREAKOUT", cards:["The German ships leave the Baltic and head toward Norway.","British reconnaissance identifies them in Norwegian waters.","Their destination is the Atlantic, where merchant convoys carry vital supplies."]),
 .init(date:"23 MAY", title:"Contact in the strait", tag:"02 / THE SEARCH", cards:["Bismarck and Prinz Eugen pass between Greenland and Iceland.","British cruisers Suffolk and Norfolk locate the German ships.","Reports guide heavier British warships toward an interception."]),
 .init(date:"24 MAY", title:"Battle of Denmark Strait", tag:"03 / FIRST ENGAGEMENT", cards:["HMS Hood and HMS Prince of Wales engage the German ships.","Hood explodes and sinks. Only three of her crew survive.","Prince of Wales withdraws. Bismarck is also damaged in the action."]),
 .init(date:"24–25 MAY", title:"A change of course", tag:"04 / THE PURSUIT", cards:["Bismarck abandons the commerce-raiding mission and heads for occupied France.","Prinz Eugen separates from the battleship and continues independently.","A Swordfish strike from Victorious scores a hit, but does not stop Bismarck."]),
 .init(date:"25–26 MAY", title:"Lost, then found", tag:"05 / REACQUIRED", cards:["Bismarck breaks contact with her pursuers.","On 26 May, a Catalina flying boat locates the battleship again.","British forces now race to intercept before she reaches air cover from France."]),
 .init(date:"26 MAY / EVENING", title:"Swordfish attack", tag:"06 / THE TURNING POINT", cards:["After an earlier mistaken attack on Sheffield, Ark Royal launches another strike.","Swordfish torpedo bombers approach Bismarck through rough weather.","A torpedo hits near the stern, jamming the rudders and preventing escape."]),
 .init(date:"26–27 MAY / NIGHT", title:"Unable to escape", tag:"07 / STEERING DISABLED", cards:["Bismarck can still move, but cannot reliably steer toward safety.","Attempts to repair or overcome the steering damage fail.","British destroyers maintain pressure while the battleships close in."]),
 .init(date:"27 MAY / MORNING", title:"The final battle", tag:"08 / THE LAST ENGAGEMENT", cards:["King George V and Rodney engage Bismarck at close range.","Gunfire wrecks the battleship. Dorsetshire later fires torpedoes.","Bismarck sinks after the bombardment and crew scuttling measures."]),
 .init(date:"27 MAY 1941", title:"The pursuit ends", tag:"09 / AFTERMATH", cards:["More than two thousand people aboard Bismarck die. A little over one hundred survive.","Reconnaissance, surface ships, and carrier aircraft had shaped the pursuit.","Historical sources: Royal Navy, Naval History and Heritage Command, KBismarck timeline."])
]
let white = NSColor(calibratedRed:0.89, green:0.93, blue:0.94, alpha:1)
let muted = NSColor(calibratedRed:0.46, green:0.60, blue:0.66, alpha:1)
let gold = NSColor(calibratedRed:0.94, green:0.69, blue:0.35, alpha:1)
let teal = NSColor(calibratedRed:0.30, green:0.76, blue:0.78, alpha:1)
func color(_ c:NSColor) -> CGColor { c.cgColor }
func text(_ s:String, _ x:Double, _ y:Double, _ size:Double, _ c:NSColor = white, _ bold:Bool = false, _ width:Double = 1160) {
    let style = NSMutableParagraphStyle(); style.lineSpacing = 5
    let font = NSFont(name:bold ? "AvenirNext-DemiBold" : "AvenirNext-Regular",size:size) ?? NSFont.systemFont(ofSize:size)
    (s as NSString).draw(in:NSRect(x:x,y:y,width:width,height:110),withAttributes:[.font:font,.foregroundColor:c,.paragraphStyle:style])
}
func line(_ c:CGContext,_ points:[CGPoint],_ col:NSColor,_ width:Double=1) {
    guard let p=points.first else{return}; c.beginPath(); c.move(to:p)
    for p in points.dropFirst(){c.addLine(to:p)};c.setStrokeColor(color(col));c.setLineWidth(width);c.strokePath()
}
func poly(_ c:CGContext,_ p:[CGPoint],_ col:NSColor) {
    c.beginPath();c.addLines(between:p);c.closePath();c.setFillColor(color(col));c.fillPath()
}
func ship(_ c:CGContext,_ x:Double,_ y:Double,_ scale:Double,_ angle:Double,_ tint:NSColor=teal) {
    // Orthographic projection of a simplified solid hull and deck structures.
    func p(_ a:Double,_ b:Double,_ z:Double)->CGPoint {
        let u=a*cos(angle)-b*sin(angle), v=a*sin(angle)+b*cos(angle)
        return CGPoint(x:x+u*scale,y:y+v*0.48*scale-z*scale)
    }
    func box(_ a:Double,_ b:Double,_ l:Double,_ w:Double,_ z:Double,_ h:Double){
        poly(c,[p(a,b,z),p(a+l,b,z),p(a+l,b,z+h),p(a,b,z+h)],tint.withAlphaComponent(0.45))
        poly(c,[p(a+l,b,z),p(a+l,b+w,z),p(a+l,b+w,z+h),p(a+l,b,z+h)],tint.withAlphaComponent(0.65))
        poly(c,[p(a,b,z+h),p(a+l,b,z+h),p(a+l,b+w,z+h),p(a,b+w,z+h)],tint)
    }
    let hull:[(Double,Double)] = [(-200,0),(-155,-28),(145,-28),(205,0),(145,28),(-155,28)]
    poly(c,hull.map{p($0.0,$0.1,0)},NSColor(calibratedWhite:0.08,alpha:1))
    for i in 0..<hull.count {let a=hull[i],b=hull[(i+1)%hull.count];poly(c,[p(a.0,a.1,0),p(b.0,b.1,0),p(b.0,b.1,15),p(a.0,a.1,15)],tint.withAlphaComponent(0.5))}
    poly(c,hull.map{p($0.0,$0.1,15)},NSColor(calibratedRed:0.36,green:0.43,blue:0.44,alpha:1))
    box(-65,-17,115,34,15,18);box(-26,-12,40,24,33,30);box(30,-9,20,18,33,24)
    for a in [-135.0,-90.0,90.0,140.0] {box(a,-13,24,26,15,13);for b in [-6.0,6.0] {line(c,[p(a+12,b,26),p(a+45,b,26)],white,3*scale)}}
    line(c,[p(-14,0,63),p(-14,0,105)],muted,2);line(c,[p(-37,0,88),p(9,0,88)],muted,1)
}
func plane(_ c:CGContext,_ x:Double,_ y:Double,_ s:Double) {
    c.saveGState();c.translateBy(x:x,y:y);c.scaleBy(x:s,y:s)
    poly(c,[CGPoint(x:-40,y:0),CGPoint(x:35,y:-5),CGPoint(x:45,y:0),CGPoint(x:35,y:5)],white)
    for yy in [-7.0,7.0]{poly(c,[CGPoint(x:-10,y:yy-35),CGPoint(x:7,y:yy-35),CGPoint(x:12,y:yy+35),CGPoint(x:-10,y:yy+35)],teal)}
    line(c,[CGPoint(x:43,y:-13),CGPoint(x:43,y:13)],gold,2);c.restoreGState()
}
func render(_ t:Double, _ c:CGContext) {
    let i=min(9,Int(t/30)), local=t-Double(i*30), ch=chapters[i], card=min(2,Int(local/10))
    c.setFillColor(NSColor(calibratedRed:0.025,green:0.065,blue:0.095,alpha:1).cgColor);c.fill(CGRect(x:0,y:0,width:W,height:H))
    c.saveGState();c.translateBy(x:0,y:Double(H));c.scaleBy(x:1,y:-1)
    NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=NSGraphicsContext(cgContext:c,flipped:true)
    for y in stride(from:235.0,through:530,by:25){
        let points=stride(from:40.0,through:1240,by:12).map{ x in CGPoint(x:x,y:y+sin(x/95+t*0.6+y)*3) }
        line(c,points,muted.withAlphaComponent(0.10))
    }
    text("NORTH ATLANTIC  /  1941",60,30,14,muted,true)
    text(String(format:"%02d / 10",i+1),1110,30,14,muted,true)
    text(ch.date,60,83,18,gold,true)
    text(ch.title,60,117,48,white,true)
    text(ch.tag,62,184,13,muted,true)
    let phase=local/30
    if [1,2,4,5].contains(i) {
        // Schematic ocean chart: positions and routes are illustrative.
        poly(c,[CGPoint(x:185,y:255),CGPoint(x:275,y:270),CGPoint(x:310,y:335),CGPoint(x:265,y:390),CGPoint(x:210,y:355)],muted.withAlphaComponent(0.16))
        poly(c,[CGPoint(x:650,y:255),CGPoint(x:705,y:265),CGPoint(x:720,y:290),CGPoint(x:660,y:303),CGPoint(x:625,y:280)],muted.withAlphaComponent(0.16))
        poly(c,[CGPoint(x:960,y:330),CGPoint(x:985,y:380),CGPoint(x:970,y:430),CGPoint(x:930,y:405)],muted.withAlphaComponent(0.16))
        text("GREENLAND",160,400,12,muted);text("ICELAND",630,310,12,muted);text("BRITAIN",940,450,12,muted)
        let route=[CGPoint(x:820,y:275),CGPoint(x:610,y:285),CGPoint(x:420,y:340),CGPoint(x:540,y:420),CGPoint(x:830,y:450)]
        line(c,route,muted.withAlphaComponent(0.3),2)
        let progress=(Double(i-1)/5+phase/5).truncatingRemainder(dividingBy:1), f=progress*4, seg=min(3,Int(f)), q=f-Double(seg)
        let pos=CGPoint(x:route[seg].x+(route[seg+1].x-route[seg].x)*q,y:route[seg].y+(route[seg+1].y-route[seg].y)*q)
        line(c,Array(route.prefix(seg+1))+[pos],gold,3)
        c.setStrokeColor(teal.withAlphaComponent(0.4).cgColor);c.setLineWidth(1)
        let r=18+local.truncatingRemainder(dividingBy:3)*14;c.strokeEllipse(in:CGRect(x:pos.x-r,y:pos.y-r,width:2*r,height:2*r))
        ship(c,pos.x,pos.y,0.35,0.2)
        text("SCHEMATIC ROUTE / NOT TO SCALE",60,480,11,muted)
    } else {
        let ang = -0.12+sin(local/20)*0.12
        ship(c,690+sin(local/8)*12,397,1.7,ang,i==8 ? muted:teal)
        if i==3 || i==8 {
            ship(c,235,320,0.58,0.3,muted)
            let q=local.truncatingRemainder(dividingBy:4)/4
            line(c,[CGPoint(x:300,y:310),CGPoint(x:300+360*q,y:310+60*q)],gold.withAlphaComponent(1-q),2)
            let r=5+q*24;c.setStrokeColor(gold.withAlphaComponent(1-q).cgColor);c.strokeEllipse(in:CGRect(x:670-r,y:370-r,width:r*2,height:r*2))
        }
        if i==6 { let q=local.truncatingRemainder(dividingBy:10)/10;plane(c,180+q*650,280,0.9);plane(c,110+q*650,235,0.6)
            line(c,[CGPoint(x:410+q*180,y:430),CGPoint(x:450+q*200,y:420)],gold,3)
        }
        if i==7 {
            c.setStrokeColor(gold.cgColor);c.setLineWidth(2);c.strokeEllipse(in:CGRect(x:300,y:340,width:120,height:100))
            text("RUDDERS JAMMED",62,475,13,gold,true)
            line(c,[CGPoint(x:260,y:480),CGPoint(x:320,y:440)],gold,1)
        }
        text(i==0 ? "BISMARCK / SIMPLIFIED 3D FORM" : "ILLUSTRATIVE RECONSTRUCTION",60,480,11,muted)
    }
    c.setFillColor(NSColor(calibratedRed:0.04,green:0.10,blue:0.14,alpha:1).cgColor);c.fill(CGRect(x:44,y:520,width:1192,height:102))
    c.setFillColor(gold.cgColor);c.fill(CGRect(x:44,y:520,width:3,height:102))
    let alpha=min(1,(local.truncatingRemainder(dividingBy:10))/0.6)
    text(ch.cards[card],65,539,25,white.withAlphaComponent(alpha),false,1140)
    for n in 0..<10 {
        let x=62+Double(n)*125
        line(c,[CGPoint(x:x,y:658),CGPoint(x:x+106,y:658)],muted.withAlphaComponent(0.25),3)
        if n<=i {line(c,[CGPoint(x:x,y:658),CGPoint(x:x+106*(n==i ? phase:1),y:658)],n==i ? gold:teal,3)}
        text(["MAY '41","18–21","23 MAY","24 MAY","24–25","25–26","26 EVE","26–27","27 AM","AFTERMATH"][n],x,675,10,n==i ? gold:muted,true)
    }
    // Short dissolves at chapter boundaries.
    let fade=min(1,min(local/0.8,(30-local)/0.8))
    if fade<1 {c.setFillColor(NSColor.black.withAlphaComponent(1-fade).cgColor);c.fill(CGRect(x:0,y:0,width:W,height:H))}
    NSGraphicsContext.restoreGraphicsState();c.restoreGState()
}

@_silgen_name("video_open") func videoOpen(_ path:UnsafePointer<CChar>,_ w:Int32,_ h:Int32,_ fps:Int32)->Int32
@_silgen_name("video_frame") func videoFrame(_ pixels:UnsafeRawPointer)->Int32
@_silgen_name("video_close") func videoClose()->Int32
let path=root.appendingPathComponent("bismarck-timeline.mp4").path
precondition(videoOpen(path,Int32(W),Int32(H),Int32(fps)) == 0)
let pixels=UnsafeMutableRawPointer.allocate(byteCount:W*H*4,alignment:64)
let c=CGContext(data:pixels,width:W,height:H,bitsPerComponent:8,bytesPerRow:W*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.noneSkipFirst.rawValue)!
let quick=CommandLine.arguments.contains("--preview")
for frame in 0..<(quick ? 1 : fps*length) {
    try autoreleasepool {
        render(quick ? 185 : Double(frame)/Double(fps),c)
        if quick || [60,1062,2280,3120].contains(frame), let image=c.makeImage() {
            let rep=NSBitmapImageRep(cgImage:image)
            try rep.representation(using:.png,properties:[:])!.write(to:root.appendingPathComponent("preview-\(frame).png"))
        }
        precondition(videoFrame(pixels) == 0)
    }
    if frame % (fps*30)==0 {print("Rendered \(frame/fps)s");fflush(stdout)}
}
precondition(videoClose() == 0)
pixels.deallocate()
print("FINISHED")
