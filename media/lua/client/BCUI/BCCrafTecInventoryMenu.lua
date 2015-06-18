BCCrafTecInventoryMenu = {};

BCCrafTecInventoryMenu.StartCrafTec = function (player, item, requirements)
	player = getSpecificPlayer(player);
	local CrafTecItem = player:getInventory():AddItem("CrafTec.Project");
	local modData = CrafTecItem:getModData();
	modData["CrafTec"] = {
		product = item,
		requirements = requirements
	};

	ISTimedActionQueue.add(BCCrafTec:new(player, CrafTecItem, 0));
end

BCCrafTecInventoryMenu.ContinueCrafTec = function(player, item)
	player = getSpecificPlayer(player);
	ISTimedActionQueue.add(BCCrafTec:new(player, item, 0));
end

BCCrafTecInventoryMenu.InventoryMenu = function(player, context, items)
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
end

Events.OnFillInventoryObjectContextMenu.Add(BCCrafTecInventoryMenu.InventoryMenu);
