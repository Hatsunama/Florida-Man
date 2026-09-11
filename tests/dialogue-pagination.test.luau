local P=require("../src/client/UI/DialoguePagination")

local function fixture(graphemes)
 local text=table.concat(graphemes)
 local ends={}
 local bytes=0
 for _,grapheme in graphemes do bytes+=#grapheme; table.insert(ends,bytes) end
 return text,ends
end
local function ascii(text)
 local ends={}
 for index=1,#text do table.insert(ends,index) end
 return text,ends
end
local function capacity(bytes)
 return function(text) return #text<=bytes end
end
local function reassemble(text,ends,bytes,start)
 local parts={}
 local offset=start or 1
 local validEnds={}
 for _,last in ends do validEnds[last]=true end
 while offset<=#text do
  local part,last=P.Page(text,offset,ends,capacity(bytes))
  assert(part and #part>0,"a fitting grapheme must make progress")
  assert(last>=offset and validEnds[last],"page must end at a complete grapheme")
  assert(utf8.len(part),"every page must be valid UTF-8")
  table.insert(parts,part)
  offset=last+1
 end
 return table.concat(parts)
end

local text,ends=ascii("Captain Steve could not safely save this session. Please retry.")
local missing,last=P.Page(text,1,ends,capacity(0))
assert(missing==nil and last==0,"unavailable space must not consume the message")
local restored,restoredEnd=P.Page(text,1,ends,capacity(#text))
assert(restored==text and restoredEnd==#text,"a later valid layout sees the complete message")

local first,firstEnd=P.Page(text,1,ends,capacity(20))
assert(first=="Captain Steve could ","prefer a fitting word boundary")
local unread=firstEnd+1
local wide,wideEnd=P.Page(text,unread,ends,capacity(30))
local narrow,narrowEnd=P.Page(text,unread,ends,capacity(9))
assert(wide and narrow and narrowEnd<wideEnd,"smaller layout reflows the current unread page")
local expanded,expandedEnd=P.Page(text,unread,ends,capacity(30))
assert(expanded==wide and expandedEnd==wideEnd,"resize never advances the unread offset")
assert(first..reassemble(text,ends,9,unread)==text,"acknowledged prefix plus resized remainder preserves order and every byte")

local spaces,spaceEnds=ascii("  alpha\n\nbeta\t gamma  ")
assert(reassemble(spaces,spaceEnds,7)==spaces,"preserve original whitespace and newlines")
local long,longEnds=ascii("supercalifragilisticexpialidocious")
assert(reassemble(long,longEnds,5)==long,"long words split with no lost letters")

-- Explicit cluster fixtures keep this test independent of Roblox's grapheme iterator.
local unicode,unicodeEnds=fixture({"A","é","é"," ","👩‍🚀"," ","🇺🇸","!"})
assert(reassemble(unicode,unicodeEnds,12)==unicode,"combining marks, ZWJ emoji, and flags remain intact")
local cluster,clusterEnds=fixture({"👩‍🚀"})
local tooSmall,before=P.Page(cluster,1,clusterEnds,capacity(4))
assert(tooSmall==nil and before==0,"never split a grapheme that cannot fit")
local whole,wholeEnd=P.Page(cluster,1,clusterEnds,capacity(#cluster))
assert(whole==cluster and wholeEnd==#cluster,"an oversized grapheme survives until it fits")

print("PASS: dialogue page reflow, full-message retention, word boundaries, whitespace, and UTF-8 grapheme offsets")
