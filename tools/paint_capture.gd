extends RefCounted
## Captures the project's drawing geometry for offline visual review (not a GPU screenshot).
static var items: Array[String] = []

static func matrix(canvas: CanvasItem) -> String:
	var m := canvas.get_global_transform()
	return 'matrix(%f %f %f %f %f %f)' % [m.x.x,m.x.y,m.y.x,m.y.y,m.origin.x,m.origin.y]

static func points(value: PackedVector2Array) -> String:
	var pairs: PackedStringArray = []
	for p in value:
		pairs.append('%f,%f' % [p.x,p.y])
	return ' '.join(pairs)

static func rect(canvas: CanvasItem, box: Rect2, color: Color) -> void:
	items.append('<rect x="%f" y="%f" width="%f" height="%f" fill="#%s" fill-opacity="%f" transform="%s"/>' % [box.position.x,box.position.y,box.size.x,box.size.y,color.to_html(false),color.a,matrix(canvas)])

static func polygon(canvas: CanvasItem, vertices: PackedVector2Array, color: Color) -> void:
	items.append('<polygon points="%s" fill="#%s" fill-opacity="%f" transform="%s"/>' % [points(vertices),color.to_html(false),color.a,matrix(canvas)])

static func polyline(canvas: CanvasItem, vertices: PackedVector2Array, color: Color, width: float, _antialias: bool) -> void:
	items.append('<polyline points="%s" fill="none" stroke="#%s" stroke-opacity="%f" stroke-width="%f" stroke-linecap="square" stroke-linejoin="miter" transform="%s"/>' % [points(vertices),color.to_html(false),color.a,width,matrix(canvas)])
