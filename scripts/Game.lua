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

	self.hud = TextBuilder:build(ctx.user_interfaces[0], {
		font_size = 40,
		widget = {
			foreground = Brush.Solid(Color.BLACK)
		}
	})
end

---@param ctx PluginContext
function Game:update(ctx)
	ctx.user_interfaces[0]:send_message(TextMessage:text(
		self.hud,
		MessageDirection.ToWidget,
		string.format("Wounds: %s\nKilled Guards: %s", self.wounds, self.frags)
	))
end

function Game:inc_frags()
	self.frags = self.frags + 1
end

function Game:inc_wounds()
	self.wounds = self.wounds + 1
end
