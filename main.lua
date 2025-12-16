local TILE_SIZE = 32
local CHEATCODE = false

local TILES = {
	EMPTY = 0,
	WALL = 1,
	DEATH = 2,
	PLAYER_ITEM = 3,
	TARGET_ITEM = 4,
	GRASS = 5,
	PLAYER_ITEM_FILL = -3,
	TARGET_ITEM_FILL = -4,
}

local COLORS = {
	PLAYER = {52/235, 229/235, 1},
	TARGET = {0, 1, 0},
	WALL = {166/235, 166/235, 166/235},
	DEATH = {1, 0, 0},
	WHITE = {1, 1, 1},
	BLACK = {0, 0, 0},
}

local changeLevel

-- Entity factory function to reduce duplication
function createEntity(params)
	local entity = {
		grid_x = params.grid_x,
		grid_y = params.grid_y,
		act_x = params.act_x,
		act_y = params.act_y,
		speed = params.speed,
		emotion = "neutral",
		deathcount = 0,
		collectibles_to_collect = 0,
		collectibles_collected = 0,
		color = params.color,
		collectible_type = params.collectible_type,
		is_Frozen = false,
	}
	return entity
end

function love.load()
	love.graphics.setDefaultFilter("nearest", "nearest")
	levels = require("levels")
	level = 1
	totaldeaths = 2

	-- Initialize entities with placeholder positions. changeLevel will set the real ones.
	player = createEntity({
		grid_x = 0, grid_y = 0, act_x = 0, act_y = 0, speed = 50,
		color = COLORS.PLAYER, collectible_type = TILES.PLAYER_ITEM
	})
    target = createEntity({
		grid_x = 0, grid_y = 0, act_x = 0, act_y = 0, speed = 100,
		color = COLORS.TARGET, collectible_type = TILES.TARGET_ITEM
	})

	player_emotion_sprites = {
		neutral = love.graphics.newImage("sprites/player_neutral.png"),
		sad = love.graphics.newImage("sprites/player_sad.png"),
		happy = love.graphics.newImage("sprites/player_happy.png")
	}

	target_emotion_sprites = {
		neutral = love.graphics.newImage("sprites/target_neutral.png"),
		sad = love.graphics.newImage("sprites/target_sad.png"),
		happy = love.graphics.newImage("sprites/target_happy.png")
	}

	wall_sprites = {
		one = love.graphics.newImage("sprites/rock_1.png"),
		two = love.graphics.newImage("sprites/rock_2.png"),
		lava = love.graphics.newImage("sprites/lava.png"),
		grass = love.graphics.newImage("sprites/grass.png")
	}

	love.graphics.setNewFont("fonts/Pix32.ttf", 14)
	sound = {}
	sound.collision = love.audio.newSource("sound/collision.wav", "static")
	sound.music = love.audio.newSource("sound/music.wav", "stream")
	sound.collision:setVolume(0.2)
	sound.music:setVolume(0.3)
	sound.music:setLooping(true)
	sound.music:play()

    -- win flag: becomes true when player lands on the same grid cell as the target
    win = false
	winTimer = 0
	winHoldDuration = 3.5 -- time to hold the banner before auto-advancing

	changeLevel(level)
end

function love.update(dt)
	-- Abstracted entity
	local function updateEntityPosition(entity)
		entity.act_y = entity.act_y - ((entity.act_y - entity.grid_y) * entity.speed * dt)
		entity.act_x = entity.act_x - ((entity.act_x - entity.grid_x) * entity.speed * dt)
	end

	updateEntityPosition(player)
	updateEntityPosition(target)

	-- handle win timer: auto-advance to next level
	if win then
		winTimer = winTimer + dt
		if winTimer >= winHoldDuration then
			-- advance to next level automatically
			changeLevel(level + 1)
		end
	end
end

function love.draw()

    if level > levels.count() then
        drawEndScreen()
        return
    end
    
    math.randomseed(os.time())
    -- draw map tiles first
        for y=1, #map do
            for x=1, #map[y] do
                local tile = map[y][x]
                if tile == TILES.WALL then
                	local intRandom = math.random(2)
                	if intRandom == 1 then
                    	love.graphics.setColor(COLORS.WHITE)
                    	love.graphics.draw(wall_sprites.one, x * TILE_SIZE, y * TILE_SIZE, 0, 1, 1)
                	else
                    	love.graphics.setColor(COLORS.WHITE)
                    	love.graphics.draw(wall_sprites.two, x * TILE_SIZE, y * TILE_SIZE)
                	end
                	love.graphics.setColor(COLORS.WHITE)
                	love.graphics.rectangle("line", x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
                elseif tile == TILES.DEATH then
                    love.graphics.setColor(COLORS.WHITE)
                    love.graphics.draw(wall_sprites.lava, x * TILE_SIZE, y * TILE_SIZE, 0, 1, 1)
					love.graphics.rectangle("line", x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
				elseif tile == TILES.GRASS then
					love.graphics.setColor(COLORS.WHITE)
					love.graphics.draw(wall_sprites.grass, x * TILE_SIZE, y * TILE_SIZE, 0, 1, 1)
                elseif tile == TILES.PLAYER_ITEM then
                    local c_size = TILE_SIZE / 2
                    local c_offset = (TILE_SIZE - c_size) / 2
                    love.graphics.setColor(COLORS.PLAYER)
                    love.graphics.rectangle("fill", x * TILE_SIZE + c_offset, y * TILE_SIZE + c_offset, c_size, c_size)
                elseif tile == TILES.TARGET_ITEM then
                    local c_size = TILE_SIZE / 2
                    local c_offset = (TILE_SIZE - c_size) / 2
                    love.graphics.setColor(COLORS.TARGET)
                    love.graphics.rectangle("fill", x * TILE_SIZE + c_offset, y * TILE_SIZE + c_offset, c_size, c_size)
                end
            end
        end

    -- draw entities on top of tiles
    local function drawEntity(entity)
        love.graphics.setColor(entity.color)
        love.graphics.rectangle("fill", entity.act_x, entity.act_y, TILE_SIZE, TILE_SIZE)
    end
    drawEntity(player)
    drawEntity(target)

    -- UI: top-right panel with level and death counts
    local windowW, windowH = love.graphics.getDimensions()
    local panelW = 240
    local panelH = 112
    local padding = 10
    local px = windowW - panelW - padding
    local py = padding

    -- panel background
    love.graphics.setColor(COLORS.BLACK[1], COLORS.BLACK[2], COLORS.BLACK[3], 0.6)
    love.graphics.rectangle("fill", px, py, panelW, panelH)

    -- panel border
    love.graphics.setColor(COLORS.WHITE[1], COLORS.WHITE[2], COLORS.WHITE[3], 0.2)
    love.graphics.rectangle("line", px, py, panelW, panelH)

    -- text inside panel
    love.graphics.setColor(COLORS.WHITE)
    local tx = px + 12
    local ty = py + 8
    -- Calculate sprite scale so the width matches the UI panel width
    local original_sprite_w = player_emotion_sprites.neutral:getWidth()
    local sprite_w = panelW
    local sprite_scale = sprite_w / original_sprite_w
    local sprite_h = player_emotion_sprites.neutral:getHeight() * sprite_scale

    love.graphics.print("Level: " .. tostring(level), tx, ty)

    -- Player & Target Stats for UI Panel
    love.graphics.print("Player deaths: " .. tostring(player.deathcount), tx, ty + 20)
    love.graphics.print("Target deaths: " .. tostring(target.deathcount), tx, ty + 40)
    love.graphics.print("Player items: " .. player.collectibles_collected .. "/" .. player.collectibles_to_collect, tx, ty + 60)
    love.graphics.print("Target items: " .. target.collectibles_collected .. "/" .. target.collectibles_to_collect, tx, ty + 80)

    love.graphics.setColor(COLORS.WHITE) -- Reset color after drawing sprites
	
	-- Draw Player and Target emotion sprites below the UI panel
    local sprite_x = px -- Align with the UI panel's x position
    local sprite_padding = 10 -- Space between sprites
    local target_sprite_y = windowH - sprite_h - padding
    local player_sprite_y = target_sprite_y - sprite_h - sprite_padding
    love.graphics.draw(player_emotion_sprites[player.emotion], sprite_x, player_sprite_y, 0, sprite_scale, sprite_scale)
    love.graphics.draw(target_emotion_sprites[target.emotion], sprite_x, target_sprite_y, 0, sprite_scale, sprite_scale)

    -- Level message panel (bottom-left). Make sure it doesn't overlap emotion sprites.
    local left_padding = 10
    local left_panel_default_w = 360
    local left_panel_h = 50
    local left_px = left_padding
    local sprite_left_edge = sprite_x
    local available_width = sprite_left_edge - (left_padding * 2)
    local left_panel_w = math.min(left_panel_default_w, math.max(120, available_width))
    local left_py = windowH - left_panel_h - left_padding

    -- Draw the left message panel
    love.graphics.setColor(0.08, 0.08, 0.08, 0.9)
    love.graphics.rectangle("fill", left_px, left_py, left_panel_w, left_panel_h, 6, 6)
    love.graphics.setColor(COLORS.WHITE[1], COLORS.WHITE[2], COLORS.WHITE[3], 0.9)
    love.graphics.rectangle("line", left_px, left_py, left_panel_w, left_panel_h, 6, 6)

    local level_message = ""
    if levels and levels.data and levels.data[level] and levels.data[level].message then
        level_message = levels.data[level].message
    end
    love.graphics.setColor(COLORS.WHITE)
    love.graphics.printf(level_message, left_px + 12, left_py + 12, left_panel_w - 24)

    -- win overlay
    if win then
        hasdrawn = false
        drawWinOverlay()
    end
end

function drawEndScreen()
	local msg = "You and your friend lived " .. tostring(totaldeaths) .. " lives until you found each other. Thanks for playing!"
	local font = love.graphics.getFont()
	local fw = font:getWidth(msg)
	local fh = font:getHeight()
	local x = (love.graphics.getWidth() - fw) / 2
	local y = (love.graphics.getHeight() - fh) / 2
	love.graphics.setColor(COLORS.WHITE)
	love.graphics.print(msg, x, y)
end

-- draw level-complete overlay when win flag is set
function drawWinOverlay()
	-- full-screen darkening
	love.graphics.setColor(COLORS.BLACK[1], COLORS.BLACK[2], COLORS.BLACK[3], 0.6)
	love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

	-- centered banner box (white text on dark)
	local boxW = 360
	local boxH = 120
	local bx = (love.graphics.getWidth() - boxW) / 2
	local by = (love.graphics.getHeight() - boxH) / 2

	love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
	love.graphics.rectangle("fill", bx, by, boxW, boxH, 6, 6)
	love.graphics.setColor(COLORS.WHITE[1], COLORS.WHITE[2], COLORS.WHITE[3], 0.9)
	love.graphics.rectangle("line", bx, by, boxW, boxH, 6, 6)

	-- banner text
	love.graphics.setColor(COLORS.WHITE)
	local title = "LEVEL COMPLETE"
	local subtitle = " You lived " .. tostring(player.deathcount + 1) .. " lives" .. " and buddy lived " .. tostring(target.deathcount + 1) .. " lives\n		until you fund each other "
	-- if win
	local titleW = love.graphics.getFont():getWidth(title)
	local subtitleW = love.graphics.getFont():getWidth(subtitle)
	love.graphics.print(title, bx + (boxW - titleW) / 2, by + 20)
	love.graphics.print(subtitle, bx + (boxW - subtitleW) / 2, by + 60)
end

-- target moves opposite direction as player
function love.keypressed(key)
	-- during win overlay, only accept continue or replay
	if win then
		if key == "return" or key == "enter" then
			changeLevel(level + 1)
			return
		else
			return
		end
	end

	local player_dx, player_dy = 0, 0

	if key == "up" then
		player_dx, player_dy = 0, -1
		player.emotion = "neutral"
		target.emotion = "neutral"
	elseif key == "down" then
		player_dx, player_dy = 0, 1
		player.emotion = "neutral"
		target.emotion = "neutral"
	elseif key == "left" then
		player_dx, player_dy = -1, 0
		player.emotion = "neutral"
		target.emotion = "neutral"
	elseif key == "right" then
		player_dx, player_dy = 1, 0
		player.emotion = "neutral"
		target.emotion = "neutral"
	elseif key == "space" and CHEATCODE == true then
		target.is_Frozen = not target.is_Frozen
		return
	else
		return -- Not a movement key
	end

	-- Move player
	if canMove(player, player_dx, player_dy) then
		player.grid_x = player.grid_x + player_dx * TILE_SIZE
		player.grid_y = player.grid_y + player_dy * TILE_SIZE
	else
		sound.collision:play()
	end

	-- Move target (opposite direction)
	if canMove(target, -player_dx, -player_dy) and (target.is_Frozen == false) then
		target.grid_x = target.grid_x - player_dx * TILE_SIZE
		target.grid_y = target.grid_y - player_dy * TILE_SIZE
	else
		sound.collision:play()
	end

	-- Check for events (death, collectibles) for both entities
	if checkEntityEvents(player) then return end
	if checkEntityEvents(target) then return end

	-- check win: show win overlay
	local all_player_items = player.collectibles_collected == player.collectibles_to_collect
	local all_target_items = target.collectibles_collected == target.collectibles_to_collect
	if player.grid_x == target.grid_x and player.grid_y == target.grid_y and all_player_items and all_target_items then
		win = true
		winTimer = 0
		player.emotion = "happy"
		target.emotion = "happy"
	end
end

-- Checks if an entity can move
function canMove(entity, dx, dy)
	local next_grid_y = (entity.grid_y / TILE_SIZE) + dy
	local next_grid_x = (entity.grid_x / TILE_SIZE) + dx
	if not map[next_grid_y] or not map[next_grid_y][next_grid_x] then return false end -- out of bounds
	return map[next_grid_y][next_grid_x] ~= TILES.WALL -- not a wall
end

-- Checks for death and collectible events for an entity
function checkEntityEvents(entity)
	local ty = entity.grid_y / TILE_SIZE
	local tx = entity.grid_x / TILE_SIZE
	local tile = map[ty] and map[ty][tx]

	if tile == TILES.DEATH then
		entity.emotion = "sad"
		entity.deathcount = entity.deathcount + 1
		totaldeaths = totaldeaths + 1
		changeLevel(level)
		return true -- level changed, stop further processing
	elseif tile == entity.collectible_type then
		entity.collectibles_collected = entity.collectibles_collected + 1
		map[ty][tx] = map[ty][tx] * -1 -- remove collectible from map
	end
	return false
end

-- changeLevel: switches the current map and resets entities for the given level
function changeLevel(newLevel)
	if newLevel > levels.count() then
		-- no more levels
		map = {}
		return
	end

	-- Get all level data at once
	level = newLevel
	local p_start_x, p_start_y, t_start_x, t_start_y
	map, p_start_x, p_start_y, t_start_x, t_start_y = levels.get(level)
	win = false
	winTimer = 0

	-- reset collectibles
	local function countCollectibles(entity)
		entity.collectibles_to_collect = 0
		entity.collectibles_collected = 0
		for y=1, #map do
			for x=1, #map[y] do
				if map[y][x] == entity.collectible_type then
					entity.collectibles_to_collect = entity.collectibles_to_collect + 1
				end
			end
		end
	end
	countCollectibles(player)
	countCollectibles(target)

	-- reset player/target positions
	player.grid_x = (p_start_x - 1) * TILE_SIZE
	player.grid_y = (p_start_y - 1) * TILE_SIZE
	player.act_x = player.grid_x
	player.act_y = player.grid_y
	target.grid_x = (t_start_x - 1) * TILE_SIZE
	target.grid_y = (t_start_y - 1) * TILE_SIZE
	target.act_x = target.grid_x
	target.act_y = target.grid_y
end