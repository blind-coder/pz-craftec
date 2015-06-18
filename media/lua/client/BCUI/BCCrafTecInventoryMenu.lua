BCCrafTecInventoryMenu = {};

BCCrafTecInventoryMenu.StartCrafTec = function (player, item, requirements) -- {{{
	player = getSpecificPlayer(player);
	local CrafTecItem = player:getInventory():AddItem("CrafTec.Project");
	local modData = CrafTecItem:getModData();
	modData["CrafTec"] = {
		product = item,
		requirements = requirements
	};

	ISTimedActionQueue.add(BCCrafTec:new(player, CrafTecItem, 0));
end
-- }}}
BCCrafTecInventoryMenu.ContinueCrafTec = function(player, item) -- {{{
	player = getSpecificPlayer(player);
	ISTimedActionQueue.add(BCCrafTec:new(player, item, 0));
end
-- }}}
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

	local requirements = { any = { any = { level = 0, time = 60, progress = 0 } } };
	subMenu:addOption("Craft Stone Axe", player, BCCrafTecInventoryMenu.StartCrafTec, "Base.AxeStone", requirements);

	local requirements = {
		Engineer = {
			Woodwork = {
				level = 2,
				time = 600,
				progress = 0
			}
		},
		Electrician = {
			Electricity = {
				level = 5,
				time = 300,
				progress = 0
			}
		},
		any = {
			any = {
				level = 0,
				time = 120,
				progress = 0
			}
		}
	};
	subMenu:addOption("Craft a generator", player, BCCrafTecInventoryMenu.StartCrafTec, "Base.Generator", requirements);
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
