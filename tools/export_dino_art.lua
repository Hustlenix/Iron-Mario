local root=app.params['root']
local raw=app.open(root..'/source_art/dino_dash/runner_strip.png')
local sheet=Image(raw.cels[1].image);raw:close()
local sprite=Sprite(32,32,ColorMode.RGB)
sprite.layers[1].name='Moss Rex - original pixel artwork'
local names={'run-left','run-right','jump','duck','bump'}
for i=1,5 do
 if i>1 then sprite:newEmptyFrame() end
 local im=Image(32,32,ColorMode.RGB)
 im:drawImage(sheet,Point(-(i-1)*32,0))
 sprite:newCel(sprite.layers[1],i,im,Point(0,0))
 sprite.frames[i].duration=0.1
 local tag=sprite:newTag(i,i);tag.name=names[i]
end
sprite:saveAs(root..'/source_art/dino_dash/runner.aseprite')
sprite:close()
