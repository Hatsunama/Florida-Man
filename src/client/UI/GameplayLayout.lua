--!strict
-- Numeric layout rules are shared by presentation and viewport regression tests.
local Layout = {}
export type Rect = { x: number, y: number, width: number, height: number }
function Layout.Hud(width: number): Rect
	return { x=8, y=4, width=math.min(600,math.max(0,width-16)), height=44 }
end
function Layout.TouchControls(width: number,height: number): Rect
	return {x=0,y=height-120,width=width,height=112}
end
function Layout.Dialogue(width: number,height: number,large: boolean,touch: boolean): Rect
	local room=height-58-(if touch then 120 else 32)-8
	return {x=12,y=58,width=math.min(400,math.max(0,width-24)),height=if room<64 then 0 else math.min(if large then 136 else 116,room)}
end
function Layout.Overlaps(a: Rect,b: Rect): boolean
	return a.width>0 and a.height>0 and b.width>0 and b.height>0 and a.x<b.x+b.width and b.x<a.x+a.width and a.y<b.y+b.height and b.y<a.y+a.height
end
return Layout
