class_name Battle3DUI
extends RefCounted
## Helper estático para montagem e atualização de elementos visuais do Battle3D.

const IP_COM_THRESHOLD: float = 0.75


static func update_ip_markers(ip_markers_container: Control, combatants: Array[Dictionary]) -> void:
	if ip_markers_container == null:
		return

	for child in ip_markers_container.get_children():
		child.queue_free()

	var bar_width: float = ip_markers_container.size.x
	if bar_width < 1.0:
		bar_width = 240.0  # fallback antes do primeiro frame de layout

	# Linha divisória no ponto COM (75%)
	var com_marker: ColorRect = ColorRect.new()
	com_marker.color = Color(0.9, 0.8, 0.1, 0.7)
	com_marker.size = Vector2(
		1.5, ip_markers_container.size.y if ip_markers_container.size.y > 0.0 else 10.0
	)
	com_marker.position = Vector2(IP_COM_THRESHOLD * bar_width - 0.75, 0)
	ip_markers_container.add_child(com_marker)

	# Marcador por combatente vivo
	for c in combatants:
		if c["hp"] <= 0:
			continue

		var state_tag: String
		var state_color: Color
		match c["state"]:
			"command":
				state_tag = " COM!"
				state_color = Color(1.0, 0.95, 0.1)
			"act":
				state_tag = " ACT▶"
				state_color = Color(1.0, 0.35, 0.1)
			"executing":
				state_tag = " ★EXE"
				state_color = Color(1.0, 0.2, 0.8)
			_:
				state_tag = ""
				state_color = c["marker_color"]

		var short_name: String = c["name"].substr(0, 4)
		var marker: Label = Label.new()
		marker.text = "%s%s%s" % [c.get("marker_symbol", "◆"), short_name, state_tag]
		marker.add_theme_font_size_override("font_size", 8)
		marker.modulate = state_color if state_tag != "" else c["marker_color"]
		marker.tooltip_text = (
			"%s · IP: %.0f%%  HP: %d/%d" % [c["name"], c["ip"] * 100, c["hp"], c["max_hp"]]
		)

		var x_pos: float = clampf(c["ip"] * bar_width - 12.0, 0.0, bar_width - 40.0)
		marker.position = Vector2(x_pos, 0)
		ip_markers_container.add_child(marker)

		if c["is_player"] and c.get("max_sp", 0) > 0:
			var sp_bar: ColorRect = ColorRect.new()
			var sp_ratio: float = float(c.get("sp", 0)) / float(c["max_sp"])
			var sp_bar_max_w: float = 28.0
			sp_bar.color = (
				Color(0.2, 0.6, 1.0, 0.9) if c["id"] == "ragg" else Color(0.7, 0.3, 1.0, 0.9)
			)
			sp_bar.size = Vector2(sp_ratio * sp_bar_max_w, 2.0)
			sp_bar.position = Vector2(x_pos, -4.0)
			ip_markers_container.add_child(sp_bar)


static func update_status_display(status_label: Label, combatants: Array[Dictionary]) -> void:
	if status_label == null:
		return
	var text: String = "PARTY:\n"
	for c in combatants:
		if c["is_player"]:
			text += (
				"%s: %d/%d HP | %d/%d MP | SP:%d\n"
				% [c["name"], c["hp"], c["max_hp"], c["mp"], c["max_mp"], c.get("sp", 0)]
			)
	text += "\nINIMIGOS:\n"
	for c in combatants:
		if not c["is_player"]:
			var status: String
			if c["hp"] <= 0:
				status = "DERROTADO"
			else:
				var state_tag: String = " [ACT!]" if c["state"] == "act" else ""
				status = "%d/%d HP%s" % [c["hp"], c["max_hp"], state_tag]
			text += "%s: %s\n" % [c["name"], status]
	status_label.text = text


static func show_damage_popup(
	target_node: Node3D, amount: int, is_cancel: bool, tag: String = ""
) -> void:
	if target_node == null:
		return
	var label: Label3D = Label3D.new()
	var tag_str: String = " [%s]" % tag if tag != "" else ""
	var cancel_str: String = " CANCEL!" if is_cancel else ""
	label.text = "-%d%s%s" % [amount, tag_str, cancel_str]
	label.font_size = 20
	label.pixel_size = 0.007
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = (
		Color(1.0, 0.15, 0.1)
		if is_cancel
		else (Color(1.0, 0.85, 0.1) if tag == "CRIT" else Color(0.9, 0.95, 1.0))
	)
	label.outline_size = 4
	label.outline_modulate = Color(0, 0, 0, 1)
	target_node.add_child(label)
	label.global_position = target_node.global_position + Vector3(randf_range(-0.3, 0.3), 1.4, 0)

	var tween: Tween = target_node.create_tween()
	tween.tween_property(label, "global_position", label.global_position + Vector3(0, 0.9, 0), 0.85)
	tween.finished.connect(label.queue_free)
