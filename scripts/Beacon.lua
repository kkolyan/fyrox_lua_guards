---@uuid 7c259fd2-fdb9-453b-a7ef-19cdd85428cc
---@class Beacon : Script
Beacon = script_class()

---@param ctx ScriptContext
function Beacon:on_update(ctx)
	local pos = ctx.scene.graph[ctx.handle]:global_position()
	table.insert(ctx.plugins:get_mut("Game").beacons, pos)
	ctx.scene.graph:remove_node(ctx.handle);
	print("beacon registered: {:?}", ctx.handle);
end
