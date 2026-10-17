/** Manifest-driven pixel renderer shared by the lab and future Canvas games. */
export class PixelAssets {
  constructor(manifest, images) { this.manifest=manifest; this.images=images; this.entries=new Map(manifest.assets.map(a=>[a.id,a])); }
  static async load(url,{ids=null}={}) {
    const manifestURL=new URL(url,location.href);
    const response=await fetch(manifestURL); if(!response.ok) throw new Error('Asset manifest unavailable');
    const manifest=await response.json(), images=new Map();
    const requested=ids?manifest.assets.filter(a=>ids.includes(a.id)):manifest.assets;
    if(ids&&new Set(ids).size!==requested.length)throw new Error('Requested asset ID not in manifest');
    await Promise.all(requested.map(async a=>{
      const image=new Image(); image.src=new URL(a.file,manifestURL).href; await image.decode();
      if(image.width!==a.size[0]||image.height!==a.size[1]) throw new Error('Image size mismatch: '+a.id);
      images.set(a.id,image);
    }));
    return new PixelAssets(manifest,images);
  }
  get(id) { const a=this.entries.get(id); if(!a)throw new Error('Unknown asset: '+id); return a; }
  frame(id,time=0,reducedMotion=false) { const a=this.get(id); return reducedMotion ? (a.reduced_motion_frame||0) : Math.floor(Math.max(0,time)*a.fps)%a.frames; }
  draw(ctx,id,x,y,{frame=0,scale=1}={}) {
    const a=this.get(id),[w,h]=a.frame_size;
    if(!Number.isInteger(scale)||scale<1)throw new Error('Use positive integer sprite scale');
    if(!Number.isInteger(frame)||frame<0||frame>=a.frames)throw new Error('Frame outside sprite strip');
    ctx.imageSmoothingEnabled=false;
    if(!this.images.has(id))throw new Error('Asset was not loaded: '+id);
    ctx.drawImage(this.images.get(id),frame*w,0,w,h,Math.round(x),Math.round(y),w*scale,h*scale);
  }
  panel(ctx,id,x,y,width,height) {
    const a=this.get(id),[l,t,r,b]=a.nine_patch||[0,0,0,0],im=this.images.get(id),[w,h]=a.frame_size;
    if(!this.images.has(id))throw new Error('Asset was not loaded: '+id);
    if(width<l+r||height<t+b)throw new Error('Panel too small for its margins');
    const sx=[0,l,w-r],sy=[0,t,h-b],sw=[l,w-l-r,r],sh=[t,h-t-b,b];
    const dx=[x,x+l,x+width-r],dy=[y,y+t,y+height-b],dw=[l,width-l-r,r],dh=[t,height-t-b,b];
    ctx.imageSmoothingEnabled=false;
    for(let row=0;row<3;row++)for(let col=0;col<3;col++)ctx.drawImage(im,sx[col],sy[row],sw[col],sh[row],dx[col],dy[row],dw[col],dh[row]);
  }
}
