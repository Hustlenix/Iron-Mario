-- Production timeline from the clean native strips. Invoked by Aseprite itself.
local root=app.params['root']
local names={'milo','jun','bea','nia','ash','pip'}
local actions={{'idle',0,1,1},{'walk',1,6,7},{'idle_animated',2,6,5},{'hit',3,6,10},{'hurt',4,3,8}}
local directions={'left','up','right','down'}
for _,name in ipairs(names) do
  local source=app.open(root..'/assets/shared_foundation/town_cast/'..name..'_motion.png')
  local sheet=Image(source.cels[1].image)
  source:close()
  local sprite=Sprite(16,32,ColorMode.RGB)
  sprite.layers[1].name='Character pixels'
  local count=0
  local tags={}
  for _,action in ipairs(actions) do
    for direction=0,3 do
      local first=count+1
      for frame=0,action[3]-1 do
        count=count+1
        if count>1 then sprite:newEmptyFrame() end
        local image=Image(16,32,ColorMode.RGB)
        image:drawImage(sheet,Point(-(direction*action[3]+frame)*16,-action[2]*32))
        sprite:newCel(sprite.layers[1],count,image,Point(0,0))
        sprite.frames[count].duration=1/action[4]
      end
      table.insert(tags,{first,count,action[1]..'_'..directions[direction+1]})
    end
  end
  -- Add tags after frames: appending frames at a tag boundary extends that tag.
  for _,spec in ipairs(tags) do
    local tag=sprite:newTag(spec[1],spec[2])
    tag.name=spec[3]
  end
  sprite:saveAs(root..'/source_art/town_cast/'..name..'.aseprite')
  sprite:close()
end
print('ASEPRITE_TOWN: saved six editable timelines, 20 source animation tags each')
