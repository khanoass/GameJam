# RingSectorProgress.gd
extends Node2D

@export var radius: float = 20.0
@export var thickness: float = 2.0

@export var arc_span_deg: float = 60.0      # max. sichtbarer Bogen (0..360)
@export var start_angle_deg: float = 0.0 - (arc_span_deg / 2.0)
@export var clockwise: bool = true

@export var show_gutter: bool = false
@export var gutter_color: Color = Color(1,1,1,0.15)
@export var bar_color: Color = Color(0.3, 0.8, 1.0)

@export var rounded_caps: bool = false        # runde Enden mit kleinen Kreisen

# ---- Outline (voller Bogen, dünn, mit Abstand) ----
@export var show_outline: bool = true
@export var outline_gap: float = 1.0          # Abstand vom Füllbalken (radial)
@export var outline_thickness: float = 0.3    # Dicke der Outline
@export var outline_use_bar_color: bool = true
@export var offset: float = deg_to_rad(outline_gap * 4)
@export var outline_color: Color = Color(0.3, 0.8, 1.0, 1.0) # nur genutzt, wenn oben false

# ---- Dynamik ----
@export var jump_arrow_path: String = "../jump_direction_arrow" # dein Pfeil (Node2D), der Richtung/Maus folgt
@export var follow_arrow_position := false                    # true = Node zentriert sich auf den Pfeil
@export var direction_offset_deg := 0.0                      # feine Dreh-Justage (z. B. Sprite-Orientierung ausgleichen)

var _value: float = 0.0  # 0..1
var _jump_arrow: Node2D

func _ready() -> void:
	_jump_arrow = get_node_or_null(jump_arrow_path)

func set_value(p: float) -> void:
	_value = clamp(p, 0.0, 1.0)
	queue_redraw()

func _process(_delta: float) -> void:
	if _jump_arrow == null:
		return
	
	# Spieler = Parent (empfohlen: ChargeRing als Child des Players)
	var player := get_parent() as Node2D
	if player == null:
		return
		
	# --- Position dynamisch zum Pfeil (gleicher Abstand wie Pfeil) ---
	if follow_arrow_position:
		global_position = _jump_arrow.global_position
	else:
		# bleibt am Spielerzentrum, dreht sich aber mit
		global_position = player.global_position
		
	# --- Richtung des Pfeils relativ zum Spieler bestimmen ---
	var dir := (_jump_arrow.global_position - player.global_position)
	var angle := dir.angle()  # Weltwinkel der Pfeilrichtung
	
	# Node-Rotation = Pfeilrichtung (+ optionaler Offset)
	rotation = angle + deg_to_rad(direction_offset_deg)
	
func _draw() -> void:
	if thickness <= 0.0 or arc_span_deg <= 0.0:
		return
		
	var center := Vector2.ZERO
	var start := deg_to_rad(start_angle_deg)
	var span := deg_to_rad(arc_span_deg)
	var sweep := span * _value
	var aa := true
	var pts: int = max(24, int(arc_span_deg))  # Bogenqualität
	
	# Gutter (gesamter Teilbogen)
	if show_gutter:
		draw_arc(center, radius, start, start + span, pts, gutter_color, thickness, aa)
		
	# Outline: voller Bogen mit Abstand, dünn
	if show_outline and outline_thickness > 0.0:
		var out_radius := radius + outline_gap + thickness * 0.5  # außen um den Balken herum
		var inner_radius := radius - outline_gap - thickness * 0.5
		var oc
		
		if outline_use_bar_color:
			oc = bar_color
		else:
			oc = outline_color
			
		draw_arc(center, out_radius, start - offset, start + span + offset, pts, oc, outline_thickness, aa)
		# NEU: Seitenlinien von Outline-Enden zum Zentrum
		var p_start_out = center + Vector2.RIGHT.rotated(start - offset) * out_radius
		var p_end_out   = center + Vector2.RIGHT.rotated(start + span + offset) * out_radius
		var p_start_in = center + Vector2.RIGHT.rotated(start - offset) * inner_radius
		var p_end_in   = center + Vector2.RIGHT.rotated(start + span + offset) * inner_radius
		draw_line(p_start_out, p_start_in, oc, outline_thickness, aa)
		draw_line(p_end_out, p_end_in, oc, outline_thickness, aa)
		
	# Fortschritt
	if sweep > 0.0001:
		draw_arc(center, radius, start, start + sweep, max(12, int(arc_span_deg * _value)), bar_color, thickness, false)
		
		if rounded_caps:
			var rcap := thickness * 0.5
			var p0 := center + Vector2.RIGHT.rotated(start) * radius
			var p1 := center + Vector2.RIGHT.rotated(start + sweep) * radius
			draw_circle(p0, rcap, bar_color)
			draw_circle(p1, rcap, bar_color)
