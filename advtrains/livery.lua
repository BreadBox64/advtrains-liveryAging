-- Helpers
local function is_hex(color)
	if color:len() ~= 7 then return nil end
	return color:match("#%x%x%x%x%x%x")
end

local function rgb_to_hex(r, g, b)
	return string.format("#%02X%02X%02X", r, g, b)
end

local function hex_to_rgb(hex)
	hex = hex:gsub("#","")
	local rgb = {
		tonumber("0x"..hex:sub(1,2)),
		tonumber("0x"..hex:sub(3,4)),
		tonumber("0x"..hex:sub(5,6)),
	}
	return rgb
end

-- Dye Filling formspec
local function show_dye_form(itemstack, player)
	local dye_count = minetest.deserialize(itemstack:get_meta():get_string("dye_count"))

end

-- Painter formspec
local function show_painter_form(itemstack, player)
	local meta = itemstack:get_meta()
	local primary_color = meta:get_string("primary_color")
	local primary_alpha = tonumber(meta:get_string("primary_alpha"))
	if primary_alpha == nil then
		primary_color, primary_alpha = "#FFFFFF", 128
	end
	local secondary_color = meta:get_string("secondary_color")
	local secondary_alpha = tonumber(meta:get_string("secondary_alpha"))
	if secondary_alpha == nil then
		secondary_color, secondary_alpha = "#FFFFFF", 128
	end

	minetest.show_formspec(player:get_player_name(), "advtrains:painter",
		-- Init formspec
		"size[6,5;true]"..
		"position[0.5, 0.45]"..
		"button[2,4.5;2,1;set;Set paint colors]"..

		-- Primary Color
		"container[0.56,0]"..
		--  Hex/Alpha fields
		"field[0.2,3;2,0.8;primary_hex;        Hex Color;"..primary_color.."]"..
		"field[0.2,4;2,0.8;primary_alpha;     Alpha (0-255);"..tostring(primary_alpha).."]"..
		--  Preview
		"label[0.44,0;Primary:]"..
		"image[0,0.5;2,2;advtrains_metal_base.png^[colorize:"..primary_color..":"..tostring(primary_alpha).."]"..
		"container_end[]"..

		-- Secondary Color
		"container[3.56,0]"..
		--  Hex/Alpha fields
		"field[0.2,3;2,0.8;secondary_hex;        Hex Color;"..secondary_color.."]"..
		"field[0.2,4;2,0.8;secondary_alpha;     Alpha (0-255);"..tostring(secondary_alpha).."]"..
		--  Preview
		"label[0.44,0;Secondary:]"..
		"image[0,0.5;2,2;advtrains_metal_base.png^[colorize:"..secondary_color..":"..tostring(seconday_alpha).."]"..
		"container_end[]"
	)
end

-- Initalize new painters
local function init_painter(player, itemstack)
	local meta = itemstack:get_meta()
	meta:set_string("dye_levels", minetest.serialize({0,0,0}))
	meta:set_string("primary_color", "#FFFFFF")
	meta:set_string("primary_alpha", tostring(128))
	meta:set_string("secondary_color", "#FFFFFF")
	meta:set_string("secondary_alpha", tostring(255))
	meta:set_string("description", "Livery Painter [R:000 G:000 B:000]")
	player:set_wielded_item(itemstack)
end

-- When someone trys to paint
local function on_paint(self, player, itemstack)
	local meta = itemstack:get_meta()
	if not meta:contains("dye_levels") then 
		init_painter(player, itemstack)
	end
	if advtrains.is_creative(player) then return true end
	local dye_levels = minetest.deserialize(meta:get_string("dye_levels"))
	local primary_rgb = hex_to_rgb(meta:get_string("primary_color"))
	local secondary_rgb = hex_to_rgb(meta:get_string("secondary_color"))
	local viable = true
	for i = 1, 3, 1 do
		dye_levels[i] = dye_levels[i] - ((primary_rgb[i] * 0.8) + (secondary_rgb[i] * 0.2))
		if dye_levels[i] <= 0 then
			viable = false
		end
	end
	if viable then
		meta:set_string("dye_levels", minetest.serialize(dye_levels))
		meta:set_string("description", "Livery Painter "..string.format("[R:%03i G:%03i B:%03i]", dye_levels[1]/20.48, dye_levels[2]/20.48, dye_levels[3]/20.48))
		return true -- Painting goes through
	else
		minetest.chat_send_player(player:get_player_name(), "Not enough dye to paint this wagon!")
		return false -- Painting denied
	end
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "advtrains:painter" then
		local itemstack = player:get_wielded_item()
		local meta = itemstack:get_meta()
		if itemstack:get_name() == "advtrains:painter" then
			if not meta:contains("dye_levels") then 
				init_painter(player, itemstack)
			end
			if fields.set then				
				local primary_hex = fields.primary_hex
				local secondary_hex = fields.secondary_hex
				local primary_alpha = tonumber(fields.primary_alpha)
				local secondary_alpha = tonumber(fields.secondary_alpha)
				if is_hex(primary_hex) == nil then
					primary_hex = "#FFFFFF"
				end
				if is_hex(secondary_hex) == nil then
					secondary_hex = "#FFFFFF"
				end
				if primary_alpha == nil or primary_alpha < 0 or primary_alpha > 255 then
					primary_alpha = 128
				end
				if secondary_alpha == nil or secondary_alpha < 0 or secondary_alpha > 255 then
					secondary_alpha = 128
				end

				-- Save color data to painter
				meta:set_string("primary_color", primary_hex)
				meta:set_string("primary_alpha", tostring(primary_alpha))
				meta:set_string("secondary_color", secondary_hex)
				meta:set_string("secondary_alpha", tostring(secondary_alpha))
				player:set_wielded_item(itemstack)
				show_painter_form(itemstack, player)
				return
			end
		end
	end
end)

minetest.register_tool("advtrains:painter", {
	description = attrans("Livery Painter"),
	_tt_help = attrans("A tool to customize your train's liveries!")..'\n'..attrans("Use RMB to open the color selection window,")..'\n'..attrans("and LMB to fill the painter with dye!"), -- If anyone has the tooltip mod (https://content.minetest.net/packages/Wuzzy/tt/) installed this will help explain how to use the tool
	inventory_image = "advtrains_painter.png",
	wield_scale = {x = 2, y = 2, z = 1},
	on_secondary_use = show_painter_form,
	_on_paint = on_paint
})