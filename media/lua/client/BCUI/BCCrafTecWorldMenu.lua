require "bcUtils_client"
require "bcUtils_genericTA"

BCCrafTecRecipes = {
	{
		product = "Base.AxeStone",
		ingredients = { ["Base.TreeBranch"] = 1, ["Base.SharpedStone"] = 1, ["Base.RippedSheets"] = 1},
		tools = {},
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
--table.insert(BCCrafTecRecipes, {product = product, ingredients = ingredients, requirements = requirements});
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
--table.insert(BCCrafTecRecipes, {product = product, ingredients = ingredients, tools = tools, requirements = requirements});
-- }}}
--]] 

BCCrafTecInventoryMenu = {};

BCCrafTecInventoryMenu.StartCrafTec = function (player, recipe) -- {{{
	playerObj = getSpecificPlayer(player);

	local canBuild = true;
	for ingredient,amount in pairs(recipe["ingredients"]) do
		if not BCCrafTecInventoryMenu.hasAllIngredients(player, recipe["ingredients"]) then
			canBuild = false;
		end
	end
	if not canBuild then return end

	local item = playerObj:getInventory():AddItem("CrafTec.Project");
	local modData = item:getModData();
	for ingredient,amount in pairs(recipe["ingredients"]) do
		modData["need:"..ingredient] = amount;
	end
	-- bcUtils.pline(bcUtils.dump(item));
	buildUtil.consumeMaterial({modData = modData, player = player, sq = getCell():getGridSquare(playerObj:getX(), playerObj:getY(), playerObj:getZ())});

	modData["CrafTec"] = {
		product = recipe["product"],
		requirements = recipe["requirements"]
	};

	ISTimedActionQueue.add(BCCrafTec:new(playerObj, item, 0));
end
-- }}}
BCCrafTecInventoryMenu.ContinueCrafTec = function(player, item) -- {{{
	player = getSpecificPlayer(player);
	ISTimedActionQueue.add(BCCrafTec:new(player, item, 0));
end
-- }}}
BCCrafTecInventoryMenu.hasAllIngredients = function(player, ingredients)--{{{
	local inventory = getSpecificPlayer(player):getInventory();
	for ing,cnt in pairs(ingredients) do
		if cnt > inventory:getItemCount(ing) then
			return false
		end
	end
	return true;
end
--}}}
BCCrafTecInventoryMenu.InventoryMenu = function(player, context, items) -- {{{
	item = items[1];
	if not instanceof(item, "InventoryItem") then
		item = item.items[1];
	end
	if item == nil then return end;

	local subMenu = ISContextMenu:getNew(context);
	local buildOption = context:addOption("CrafTec", item, nil);
	context:addSubMenu(buildOption, subMenu);

	if item:getFullType() == "CrafTec.Project" then
		subMenu:addOption("Continue CrafTec", player, BCCrafTecInventoryMenu.ContinueCrafTec, item)
	end

	for _,recipe in pairs(BCCrafTecRecipes) do
		for ingredient,amount in pairs(recipe["ingredients"]) do
			if item:getFullType() == ingredient then
				local o = subMenu:addOption("Craft "..recipe.product, player, BCCrafTecInventoryMenu.StartCrafTec, recipe);
				if not BCCrafTecInventoryMenu.hasAllIngredients(player, recipe["ingredients"]) then
					o.notAvailable = true;
				end
			end
		end
	end

	return;
end
-- }}}

function BCCrafTecInventoryMenu.GetItemInstance(type) -- {{{ taken from ISCraftingUI.lua
	if not BCCrafTecInventoryMenu.ItemInstances then BCCrafTecInventoryMenu.ItemInstances = {} end
	local item = BCCrafTecInventoryMenu.ItemInstances[type];
	if not item then
		item = InventoryItemFactory.CreateItem(type);
		if item then
			BCCrafTecInventoryMenu.ItemInstances[type] = item;
			BCCrafTecInventoryMenu.ItemInstances[item:getFullType()] = item;
		end
	end
	return item;
end
-- }}}

BCCrafTecInventoryMenu.ISToolTipInvRender = ISToolTipInv.render;
function ISToolTipInv:render() -- {{{
	BCCrafTecInventoryMenu.ISToolTipInvRender(self);
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
		local item = BCCrafTecInventoryMenu.GetItemInstance(tool);
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

Events.OnFillInventoryObjectContextMenu.Add(BCCrafTecInventoryMenu.InventoryMenu);
