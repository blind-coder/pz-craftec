require "bcUtils_client"

if not BCCrafTec then BCCrafTec = {} end
--[[
-- {{{
--To extend CrafTecs, just add to this object like this:
--Simple recipe:
--local recipe = {};
--recipe.product = "Makeshift chair";
--recipe.resultClass = "ISSimpleFurniture";
--recipe.images = { west = "chair_west", north = "chair_north", east = "chair_east", south = "chair_south" };
--recipe.tools = {}; -- no tools
--recipe.ingredients = { ["Base.Plank"] = 4, ["Base.RippedSheets"] = 4};
--recipe.requirements = { any = { any = { level = 0, time = 60, progress = 0 } } };
--table.insert(BCCrafTec.Recipes, recipe);
--
--More complex:
--lecal recipe = {};
--recipe.product = "Metal sheet wall";
--recipe.resultClass = "MyModMetalSheetWall";
--recipe.images = { west = "mymod_sheetwall_west", north = "mymod_sheetwall_north", east = nil, south = nil };
--recipe.tools = { ["MyMod.Blowtorch"] = true, ["MyMod.Simplegloves/MyMod.Workinggloves"] = true }; -- require a blowtorch and either simple gloves or working gloves
--recipe.ingredients = { ["MyMod.Metalsheet"] = 4, ["MyMod.Blowtorchfuel"] = 1 };
--recipe.requirements = {
--	Engineer = {
--		Woodwork = { -- need an engineer with level 2 or better in woodwoorking for 600 minutes
--			level = 2,
--			time = 600,
--			progress = 0
--		}
--	},
--	Electrician = {
--		Electricity = { -- need an electrician with level 4 in electricity for 300 minutes
--			level = 4,
--			time = 300,
--			progress = 0
--		}
--	},
--	any = {
--		any = {
--			level = 0, -- need anyone else for 120 minutes
--			time = 120,
--			progress = 0
--		}
--	}
--};
--table.insert(BCCrafTec.Recipes, recipe);
-- }}}
--]] 

BCCrafTec.Recipes = { -- {{{
	{ product = getText("Logwall"),
		resultClass = "ISWoodenWall",
		ingredients = {["Base.Log"] = 4, ["Base.RippedSheets"] = 4},
		images = { west = "carpentry_02_80", north = "carpentry_02_81", east = nil, south = nil },
		tools = {["Base.Hammer/Base.HammerStone"] = true, ["Base.Saw"] = true},
		canBarricade = false,
		requirements = { any = { any = { level = 0, time = 60, progress = 0 } } }
	},
	{ product = getText("Logwall"),
		resultClass = "ISWoodenWall",
		ingredients = { ["Base.Log"] = 4, ["Base.Twine"] = 4},
		images = { west = "carpentry_02_80", north = "carpentry_02_81", east = nil, south = nil },
		tools = {},
		canBarricade = false,
		requirements = { any = { any = { level = 0, time = 60, progress = 0 } } }
	},
	{ product = getText("Logwall"),
		resultClass = "ISWoodenWall",
		ingredients = { ["Base.Log"] = 4, ["Base.Rope"] = 2},
		images = { west = "carpentry_02_80", north = "carpentry_02_81", east = nil, south = nil },
		tools = {},
		canBarricade = false,
		requirements = { any = { any = { level = 0, time = 60, progress = 0 } } }
	}
};
-- }}}

BCCrafTec.LogwallIsValid = function(self, square) -- {{{
	if not buildUtil.canBePlace(self, square) then
		return false;
	end
	if buildUtil.stairIsBlockingPlacement(square, true, (self.nSprite==4 or self.nSprite==2)) then
		return false;
	end
	return square:isFreeOrMidair(false);
end
-- }}}
BCCrafTec.startCrafTec = function(player, recipe) -- {{{
	local crafTec = BCCrafTecObject:new(recipe);

	crafTec.player = player;
	crafTec.noNeedHammer = true; -- do not need a hammer to _start_, but maybe later to _build_
	getCell():setDrag(crafTec, player);
end
-- }}}
BCCrafTec.buildCrafTec = function(player, object) -- {{{
	BCCrafTec.consumeMaterial(player, object);
	local ta = BCCrafTecTA:new(player, object);
	ISTimedActionQueue.add(ta);
end
-- }}}
BCCrafTec.consumeMaterial = function(player, object) -- {{{ -- taken and butchered from ISBuildUtil
	player = getSpecificPlayer(player);
  local inventory = player:getInventory();
  local recipe = object:getModData()["recipe"];
  local removed = false;
	for part,amount in pairs(recipe.ingredients) do
		if not recipe.ingredientsAdded then recipe.ingredientsAdded = {}; end
		if not recipe.ingredientsAdded[part] then recipe.ingredientsAdded[part] = 0; end

		amount = amount - recipe.ingredientsAdded[part];
		local checkGround = 0;
		-- if we didn't have all the required material inside our inventory,
		-- it's because the missing materials are on the ground, we gonna check them
		if inventory:getNumberOfItem(part) < amount then
			checkGround = amount - inventory:getNumberOfItem(part);
		end
		for i=1,(amount - checkGround) do
			inventory:Remove(inventory:FindAndReturn(part));
			recipe.ingredientsAdded[part] = recipe.ingredientsAdded[part] + 1;
		end

		-- for each missing material in inventory
		if checkGround > 0 then
			-- check a 3x3 square around the player
			for x=math.floor(player:getX())-1,math.floor(player:getX())+1 do
				for y=math.floor(player:getY())-1,math.floor(player:getY())+1 do
					local square = getCell():getGridSquare(x,y,math.floor(player:getZ()));
					local wobs = square and square:getWorldObjects() or nil;

					-- do we have the needed material on the ground ?
					if wobs ~= nil then
						local itemToRemove = {};
						for m=0, wobs:size()-1 do
							local o = wobs:get(m);
							if instanceof(o, "IsoWorldInventoryObject") and o:getItem():getFullType() == part then
								table.insert(itemToRemove, o);
								checkGround = checkGround - 1;
								if checkGround == 0 then
									break;
								end
							end
						end
						for i,v in pairs(itemToRemove) do
							square:transmitRemoveItemFromSquare(v);
							square:removeWorldObject(v);
							recipe.ingredientsAdded[part] = recipe.ingredientsAdded[part] + 1;
							removed = true
						end
						if checkGround == 0 then
							break;
						end
						itemToRemove = {};
					end
				end
				if checkGround == 0 then
					break;
				end
			end
		end
	end
	if removed then ISInventoryPage.dirtyUI() end
end
--}}}
BCCrafTec.makeTooltip = function(player, recipe) -- {{{
	local toolTip = ISToolTip:new();
	toolTip:initialise();
	--toolTip:setVisible(false);
	toolTip:setName("Project: "..getText(recipe.product));
	toolTip:setTexture(recipe.images.east);

	local desc = "Project: "..recipe.product.." <LINE> ";

	local needsTools = false;
	for tools,_ in pairs(recipe.tools) do
		if not needsTools then
			needsTools = true;
			desc = desc .. "Needs tools: <LINE> ";
		end

		local first = true;
		desc = desc .. "  - ";
		for _,tool in pairs(bcUtils.split(tools, "/")) do
			local item = BCCrafTec.GetItemInstance(tool);
			if not first then
				desc = desc .. " / ";
			end
			local color = "";
			if ISBuildMenu.countMaterial(player, tool) <= 0 then
				color = " <RED> ";
			else
				color = " <GREEN> ";
			end
			desc = desc .. color..item:getDisplayName().." <RGB:1,1,1> ";
			first = false;
		end
		desc = desc .. " <LINE> ";
	end

	if recipe.started then
		-- Project on the ground
		desc = desc .. "Needs parts: <LINE> ";
		for ing,amount in pairs(recipe.ingredients) do
			local color = "";
			local item = BCCrafTec.GetItemInstance(ing);
			local avail = ISBuildMenu.countMaterial(player, ing);
			if avail + (recipe.ingredientsAdded and recipe.ingredientsAdded[ing] or 0) < amount then
				color = " <RED> ";
			else
				color = " <GREEN> ";
			end
			desc = desc .. "  - "..color..item:getDisplayName()..": "..((recipe.ingredientsAdded and recipe.ingredientsAdded[ing]) or 0).."+"..avail.."/"..amount.." <RGB:1,1,1>  <LINE> ";
		end
	else
		-- Tooltip in build menu
		desc = desc .. "Needs parts: <LINE> ";
		for ing,amount in pairs(recipe.ingredients) do
			local color = "";
			local item = BCCrafTec.GetItemInstance(ing);
			local avail = ISBuildMenu.countMaterial(player, ing); -- needs ISBuildMenu.materialOnGround above
			if (avail or 0) < amount then
				color = " <RED> ";
			else
				color = " <GREEN> ";
			end
			desc = desc .. "  - "..color..item:getDisplayName()..": "..(avail or 0).."/"..amount.." <RGB:1,1,1>  <LINE> ";
		end
	end

	for k,profession in pairs(recipe.requirements) do
		desc = desc .. "Profession: "..getText(k).." <LINE> ";
		for k,skill in pairs(profession) do
			if k ~= "any" then
				desc = desc .. "  Skill: "..getText(k).." Level "..skill["level"].." <LINE> ";
			end
			desc = desc .. "    Progress: "..skill["progress"].." / "..skill["time"].." <LINE> ";
		end
	end

	toolTip.description = desc;

	return toolTip;
end
-- }}}

BCCrafTec.GetItemInstance = function(type) -- {{{ taken from ISCraftingUI.lua
	if not BCCrafTec.ItemInstances then BCCrafTec.ItemInstances = {} end
	local item = BCCrafTec.ItemInstances[type];
	if not item then
		item = InventoryItemFactory.CreateItem(type);
		if item then
			BCCrafTec.ItemInstances[type] = item;
			BCCrafTec.ItemInstances[item:getFullType()] = item;
		end
	end
	return item;
end
-- }}}

BCCrafTec.WorldMenu = function(player, context, worldObjects) -- {{{
print(bcUtils.dump(worldObjects));
	for _,object in ipairs(worldObjects) do
		local md = object:getModData();
		if md.recipe then
			local o = context:addOption("Continue "..getText(md.recipe.product), player, BCCrafTec.buildCrafTec, object);
			o.toolTip = BCCrafTec.makeTooltip(player, md.recipe);
		end
	end

	local subMenu = ISContextMenu:getNew(context);
	local buildOption = context:addOption("CrafTec", item, nil);
	context:addSubMenu(buildOption, subMenu);

	for _,recipe in pairs(BCCrafTec.Recipes) do
		local o = subMenu:addOption(recipe.product, player, BCCrafTec.startCrafTec, recipe);
		o.toolTip = BCCrafTec.makeTooltip(player, recipe);
	end
end
-- }}}
Events.OnFillWorldObjectContextMenu.Add(BCCrafTec.WorldMenu);
