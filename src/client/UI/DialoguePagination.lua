--!strict
local Pagination={}

-- Boundaries are inclusive UTF-8 grapheme byte ends for the full, immutable message.
-- The caller advances start only after the returned page is acknowledged.
function Pagination.Page(text: string,start: number,boundaries: {number},fits: (string)->boolean): (string?,number)
 if fits(string.sub(text,start)) then return string.sub(text,start),#text end
 local lastFit,lastSpace=start-1,start-1
 local first=start
 for _,last in boundaries do
  if last<start then continue end
  if not fits(string.sub(text,start,last)) then break end
  lastFit=last
  if string.match(string.sub(text,first,last),"^%s+$") then lastSpace=last end
  first=last+1
 end
 local finish=if lastSpace>=start then lastSpace else lastFit
 if finish<start then return nil,start-1 end
 return string.sub(text,start,finish),finish
end

return Pagination
