---@class Game : Plugin
---@field player Node
---@field beacons Vector3[]
---@field frags number
---@field wounds number
---@field hud UiNode
Game = plugin_class()

---@param scene_path string
---@param ctx PluginContext
function Game:init(scene_path, ctx)
	ctx
		.async_scene_loader
		:request(scene_path.unwrap_or("data/scene.rgs"))

	ctx.async_scene_loader
		:request("data/hud.ui")

	self.hud = ctx
		.user_interfaces
		:first_mut()
		:find_handle_by_name_from_root("HUD")

	TextBuilder:new(WidgetBuilder:new():with_foreground(Brush:Solid(Color.BLACK)))
		:with_font_size(40.0)
		:build(ctx.user_interfaces:first_mut():build_ctx())
end

---@param ctx PluginContext
function Game:update(ctx)
	ctx
		.user_interfaces
		:first_mut()
		:send_message(TextMessage:text(
			self.hud,
			MessageDirection.ToWidget,
			string.format("Wounds: %s\nKilled Guards: %s", self.wounds, self.frags)
		))
end