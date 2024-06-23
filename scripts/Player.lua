---@uuid c5671d19-9f1a-4286-8486-add4ebaadaec
---@class Player : Script
---@field sensitivity number
---@field camera Node
---@field power number
---@field bullet Prefab
---@field initial_bullet_velocity number
---@field shooting_range number
---@field reload_delay_sec number
---@field private reload_sec number
---@field private published boolean
---@field private collider Node
Player = script_class()

local aim_y = 0
local forward = false
local back = false
local left = false
local right = false
local fire = false


---@param x number
function Player:turn(x, ctx)
    local self_transform = ctx.handle.local_transform_mut();
    local rot_delta = Rotation3:from_axis_angle(Vector3:y_axis(), self.sensitivity * x);
    self_transform.set_rotation(self_transform.rotation().mul(rot_delta));
end

function Player:aim(ctx, y)
    aim_y = aim_y + y * self.sensitivity;

    aim_y = aim_y.clamp(math.pi / 2.0, math.pi / 2.0);

    local camera_transform = self.camera.local_transform_mut();
    camera_transform.set_rotation(UnitQuaternion:from_axis_angle(
        Vector3:x_axis(),
        aim_y
    ));
end

function Player:fire(ctx)
    local camera_global_transform = self.camera.global_transform();
    local camera_pos = self.camera.global_position();

    local rot = camera_global_transform.fixed_view("3x3", 0, 0);
    local bullet_orientation = UnitQuaternion:from_matrix(rot);

    local prefab = self.bullet.as_ref().unwrap().clone();
    Bullet:spawn(
        ctx.scene,
        {
            prefab = prefab,
            origin = camera_pos,
            direction = bullet_orientation.transform_vector(Vector3:z_axis()),
            initial_velocity = self.initial_bullet_velocity,
            author_collider = self.collider,
            range = self.shooting_range
        }
    );
    print("bullet spawned");
end


function Player:on_init(ctx)
    local _ = ctx
        .graphics_context
        :as_initialized_mut()
        .window
        :set_cursor_grab(CursorGrabMode.Confined);

    self.collider = ctx
        .handle
        .try_get_collider(ctx.scene)
        .expect("Collider not found under Player node");
    end

function Player:on_start(ctx)
    ctx.message_dispatcher.subscribe_to("BulletHit", ctx.handle)
end

function Player:on_message(message, ctx)
    local _bullet = message.downcast_ref("BulletHit")
    if _bullet ~= nil then
        ctx.plugins.get_mut("Game"):inc_wounds()
        print("player wounded!")
    end
end

function Player:on_update(ctx)
    if self.reload_sec > 0.0 then
        self.reload_sec = self.reload_sec - ctx.dt;
    end
    if !self.published then
        self.published = true;
        ctx.plugins.get_mut("Game").player = ctx.handle;
    end

    if fire then
        if self.reload_sec <= 0.0 then
            self.reload_sec = self.reload_delay_sec;
            self.fire(ctx);
        end
    end

    local move_delta = Vector3:zero();
    if forward then
        move_delta.z = move_delta.z + 1.0
    end
    if back then
        move_delta.z = move_delta.z - 1.0
    end
    if left then
        move_delta.x = move_delta.x + 1.0
    end
    if right then
        move_delta.x = move_delta.x - 1.0
    end

    if move_delta.magnitude() > 0.001 then
        move_delta.normalize_mut();
    end

    local self_rotation = ctx.handle
        .local_transform()
        .rotation()
        .clone();
    local move_delta = self_rotation.transform_vector(move_delta);
    local force = move_delta * self.power;
    ctx.handle
        .as_rigid_body_mut()
        .apply_force(force);
end

function Player:on_os_event(event, ctx)
    do
        local event = event:as("WindowEvent")
        if event then
            do
                local event = event:as("KeyboardInput")
                if event then
                    local value = ElementState.Pressed
                    if event.physical_key:as("Code")[0] == KeyCode.KeyW then
                        forward = value
                    end
                    if event.physical_key:as("Code")[0] == KeyCode.KeyS then
                        back = value
                    end
                    if event.physical_key:as("Code")[0] == KeyCode.KeyA then
                        left = value
                    end
                    if event.physical_key:as("Code")[0] == KeyCode.KeyD then
                        right = value
                    end
                end
            end
            do
                local event = event:as("MouseInput")
                if event then
                    if event.button == MouseButton.Left then
                        fire = event.state == ElementState.Pressed
                    end
                end
            end
        end
    end
    do
        local event = event:as("DeviceEvent")
        if event then
            do
                local event = event:as("MouseMotion")
                if event then
                    local x, y = table.unpack(event.delta)
                    self:turn(-x, ctx);
                    self:aim(y, ctx);
                end
            end
        end
    end
end
