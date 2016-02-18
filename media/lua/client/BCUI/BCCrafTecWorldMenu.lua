require "bcUtils_client"
require "bcUtils_genericTA"

if not BCCrafTec then BCCrafTec = {} end
BCCrafTec.LogwallIsValid = function(self, square)
	if not buildUtil.canBePlace(self, square) then
		return false;
	end
	if buildUtil.stairIsBlockingPlacement(square, true, (self.nSprite==4 or self.nSprite==2)) then
		return false;
	end
	return square:isFreeOrMidair(false);
end

BCCrafTec.Recipes = {
	{ product = getText("Logwall"),
		ingredients = { ["Base.Log"] = 4, ["Base.RippedSheets"] = 4},
		images = { west = "carpentry_02_80", north = "carpentry_02_81", east = nil, south = nil },
		tools = {["Base.Hammer/Base.HammerStone"] = 1, ["Base.Saw"] = 1},
		canBarricade = false,
		isValid = BCCrafTec.LogwallIsValid,
		requirements = { any = { any = { level = 0, time = 60, progress = 0 } } }
	},
	{ product = getText("Logwall"),
		ingredients = { ["Base.Log"] = 4, ["Base.Twine"] = 4},
		images = { west = "carpentry_02_80", north = "carpentry_02_81", east = nil, south = nil },
		tools = {},
		canBarricade = false,
		isValid = BCCrafTec.LogwallIsValid,
		requirements = { any = { any = { level = 0, time = 60, progress = 0 } } }
	},
	{ product = getText("Logwall"),
		ingredients = { ["Base.Log"] = 4, ["Base.Rope"] = 2},
		images = { west = "carpentry_02_80", north = "carpentry_02_81", east = nil, south = nil },
		tools = {},
		canBarricade = false,
		isValid = BCCrafTec.LogwallIsValid,
		requirements = { any = { any = { level = 0, time = 60, progress = 0 } } }
	}
};
--[[
-- {{{
--To extend CrafTecs, just add to this object like this:
--Simple recipe:
--local product = "Base.AxeStone";
--local ingredients = { ["Base.TreeBranch"] = 1, ["Base.SharpedStone"] = 1, ["Base.RippedSheets"] = 1};
--local requirements = { any = { any = { level = 0, time = 60, progress = 0 } } };
--table.insert(BCCrafTec.Recipes, {product = product, ingredients = ingredients, requirements = requirements});
--
--More complex:
--local product = "Base.Generator";
--local ingredients = { ["Base.ElectronicsScrap"] = 25, ["Base.Plank"] = 5 };
--local tools = { "Base.Saw", "Base.Screwdriver" };
--local requirements = {
--	Engineer = {
--		Woodwork = {
--			level = 2,
--			time = 600,
--			progress = 0
--		}
--	},
--	Electrician = {
--		Electricity = {
--			level = 4,
--			time = 300,
--			progress = 0
--		}
--	},
--	any = {
--		any = {
--			level = 0,
--			time = 120,
--			progress = 0
--		}
--	}
--};
--table.insert(BCCrafTec.Recipes, {product = product, ingredients = ingredients, tools = tools, requirements = requirements});
-- }}}
--]] 

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
			if (recipe.ingredientsAdded and recipe.ingredientsAdded[k] or 0) < amount then
				color = " <RED> ";
			else
				color = " <GREEN> ";
			end
			desc = desc .. "  - "..color..getText(ing)..": "..((recipe.ingredientsAdded and recipe.ingredientsAdded[k]) or 0).."/"..amount.." <RGB:1,1,1>  <LINE> ";
		end
	else
		-- Tooltip in build menu
		desc = desc .. "Needs parts: <LINE> ";
		for ing,amount in pairs(recipe.ingredients) do
			local color = "";
			local avail = ISBuildMenu.countMaterial(player, ing);
			if (avail or 0) < amount then
				color = " <RED> ";
			else
				color = " <GREEN> ";
			end
			desc = desc .. "  - "..color..getText(ing)..": "..(avail or 0).."/"..amount.." <RGB:1,1,1>  <LINE> ";
		end
	end

	for k,profession in pairs(recipe.requirements) do
		desc = desc .. "Profession: "..getText(k).." <LINE> ";
		for k,skill in pairs(profession) do
			if k ~= "any" then
				desc = desc .. "  Skill: "..getText(k).." Level "..getText(skill["level"]).." <LINE> ";
			end
			desc = desc .. "    Progress: "..skill["progress"].." / "..skill["time"].." <LINE> ";
		end
	end

	toolTip.description = desc;

	return toolTip;
end
-- }}}

BCCrafTec.startCrafTec = function(player, recipe) -- {{{
	local crafTec = BCCrafTecObject:new(recipe);

	crafTec.player = player;
	crafTec.noNeedHammer = true; -- do not need a hammer to _start_, but maybe later to _build_
	getCell():setDrag(crafTec, player);
end
-- }}}
BCCrafTec.WorldMenu = function(player, context, worldObjects) -- {{{
	for _,object in pairs(worldObjects) do
		local md = object:getModData();
		if md.recipe then
			local o = context:addOption("Project: "..getText(md.recipe.product));
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

function BCCrafTec.GetItemInstance(type) -- {{{ taken from ISCraftingUI.lua
	if not BCCrafTec.ItemInstances then BCCrafTec.ItemInstances = {} end
	local item = BCCrafTec.ItemInstances[type];
	if not item then
		item = InventoryItemFactory.CreateItem(type);
		bcUtils.pline(type..": "..bcUtils.dump(item));
		if item then
			BCCrafTec.ItemInstances[type] = item;
			BCCrafTec.ItemInstances[item:getFullType()] = item;
		end
	end
	return item;
end
-- }}}
--[[
BCCrafTec.ISToolTipInvRender = ISToolTipInv.render;
function ISToolTipInv:render() -- {{{
	BCCrafTec.ISToolTipInvRender(self);
	if self.item:getFullType() ~= "CrafTec.Project" then return end;

	local th = self.height;
	local r = 0;
	local g = 0;

	local text = {};

	local modData = self.item:getModData()["CrafTec"];
	table.insert(text, "Project: "..modData["product"]);

	local needsTools = false;
	for k,tool in pairs(modData["tools"]) do
		if not needsTools then
			needsTools = true;
			table.insert(text, "Needs tools:");
		end
		local item = BCCrafTec.GetItemInstance(tool);
		table.insert(text, "  "..item:getDisplayName());
	end

	for k,profession in pairs(modData["requirements"]) do
		table.insert(text, "Profession: "..k);
		for k,skill in pairs(profession) do
			if k ~= "any" then
				table.insert(text, "  Skill: "..k.." Level "..skill["level"]);
			end
			table.insert(text, "    Progress: "..skill["progress"].." / "..skill["time"]);
		end
	end

	local y = th;
	local w = self.width;

	for _,t in ipairs(text) do
		local textHeight = getTextManager():MeasureStringY(UIFont.Small, t);
		local textWidth = getTextManager():MeasureStringX(UIFont.Small, t);
		-- self:drawText(t, 3, y+3, 1.0, 1.0, 0.8, 1, UIFont.Small);
		y = y + textHeight + 3;
		w = math.max(w, textWidth);
	end

	self:drawRect(0, th, math.max(self.width, 6+w), 6+y-th,
		self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b);
	self:drawRectBorder(0, th, math.max(self.width, 6+w), 6+y-th,
		self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);

	y = th;
	for _,t in ipairs(text) do
		local textHeight = getTextManager():MeasureStringY(UIFont.Small, t);
		self:drawText(t, 3, y+3, 1.0, 1.0, 0.8, 1, UIFont.Small);
		y = y + textHeight + 3;
	end
end
-- }}}

BCCrafTec.ContinueCrafTec = function(player, item) -- {{{
	player = getSpecificPlayer(player);
	ISTimedActionQueue.add(BCCrafTec:new(player, item, 0));
end
-- }}}
BCCrafTec.hasAllIngredients = function(player, ingredients)--{{{
	local inventory = getSpecificPlayer(player):getInventory();
	for ing,cnt in pairs(ingredients) do
		if cnt > inventory:getItemCount(ing) then
			return false
		end
	end
	return true;
end
--}}}
--]]

Events.OnFillWorldObjectContextMenu.Add(BCCrafTec.WorldMenu);
