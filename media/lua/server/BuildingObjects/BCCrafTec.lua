require "BuildingObjects/ISBuildUtil";
require "BuildingObjects/ISWoodenWall";
require "BuildingObjects/ISDoubleTileFurniture";
require "bcUtils";

-- Hotfixes
buildUtil.setInfo = function(javaObject, ISItem) -- {{{
	if  javaObject.setCanPassThrough     then  javaObject:setCanPassThrough(ISItem.canPassThrough or false);        end
	if  javaObject.setCanBarricade       then  javaObject:setCanBarricade(ISItem.canBarricade or false);            end
	if  javaObject.setThumpDmg           then  javaObject:setThumpDmg(ISItem.thumpDmg or false);                    end
	if  javaObject.setIsContainer        then  javaObject:setIsContainer(ISItem.isContainer or false);              end
	if  javaObject.setIsDoor             then  javaObject:setIsDoor(ISItem.isDoor or false);                        end
	if  javaObject.setIsDoorFrame        then  javaObject:setIsDoorFrame(ISItem.isDoorFrame or false);              end
	if  javaObject.setCrossSpeed         then  javaObject:setCrossSpeed(ISItem.crossSpeed or 1);                    end
	if  javaObject.setBlockAllTheSquare  then  javaObject:setBlockAllTheSquare(ISItem.blockAllTheSquare or false);  end
	if  javaObject.setName               then  javaObject:setName(ISItem.name or "Object");                         end
	if  javaObject.setIsDismantable      then  javaObject:setIsDismantable(ISItem.dismantable or false);            end
	if  javaObject.setCanBePlastered     then  javaObject:setCanBePlastered(ISItem.canBePlastered or false);        end
	if  javaObject.setIsHoppable         then  javaObject:setIsHoppable(ISItem.hoppable or false);                  end
	if  javaObject.setModData            then  javaObject:setModData(bcUtils.cloneTable(ISItem.modData));           end
	if  javaObject.setIsThumpable        then  javaObject:setIsThumpable(ISItem.isThumpable or true);               end

	if ISItem.containerType and javaObject:getContainer() then
		javaObject:getContainer():setType(ISItem.containerType);
	end
	if ISItem.canBeLockedByPadlock then
		javaObject:setCanBeLockByPadlock(ISItem.canBeLockedByPadlock);
	end
end
-- }}}
function ISDoubleTileFurniture:setInfo(square, north, sprite) -- {{{
	-- add furniture to our ground
	local thumpable = IsoThumpable.new(getCell(), square, sprite, north, self);
	-- name of the item for the tooltip
	buildUtil.setInfo(thumpable, self);
	-- the furniture have 200 base health + 100 per carpentry lvl
	thumpable:setMaxHealth(self:getHealth());
	-- the sound that will be played when our furniture will be broken
	thumpable:setBreakSound("breakdoor");
	square:AddSpecialObject(thumpable);
	thumpable:transmitCompleteItemToServer();

	self.javaObject = thumpable;
end
-- }}}
function ISWoodenStairs:setInfo(square, level, north, sprite, luaobject) -- {{{
	-- add stairs to our ground
	local pillarSprite = self.pillar;
	if north then
		pillarSprite = self.pillarNorth;
	end
	local thumpable = square:AddStairs(north, level, sprite, pillarSprite, luaobject);
	-- recalc the collide
	square:RecalcAllWithNeighbours(true);
	-- name of the item for the tooltip
	thumpable:setName("Wooden Stairs");
	-- we can't barricade/unbarricade the stairs
	thumpable:setCanBarricade(false);
	thumpable:setIsDismantable(true);
	-- the stairs have 500 base health + 100 per carpentry lvl
	thumpable:setMaxHealth(self:getHealth());
	thumpable:setIsStairs(true);
	thumpable:setIsThumpable(false)
	-- the sound that will be played when our stairs will be broken
	thumpable:setBreakSound("breakdoor");
	thumpable:setModData(copyTable(self.modData))
	thumpable:transmitCompleteItemToServer();

	self.javaObject = thumpable;
end
-- }}}

BCCrafTecObject = ISBuildingObject:derive("BCCrafTecObject");
BCCrafTecObject.addWoodXpOriginal = buildUtil.addWoodXp;
buildUtil.addWoodXp = function(ISItem)
	if ISItem.recipe then
		return;
	end
	BCCrafTecObject.addWoodXpOriginal(ISItem);
end

function BCCrafTecObject:create(x, y, z, north, sprite) -- {{{
  local cell = getWorld():getCell();
  self.sq = cell:getGridSquare(x, y, z);

  self.javaObject = IsoThumpable.new(cell, self.sq, "carpentry_02_56", north, self);
  buildUtil.setInfo(self.javaObject, self);
  self.javaObject:setBreakSound("breakdoor");
	self.sq:AddSpecialObject(self.javaObject);

  self.javaObject:transmitCompleteItemToServer();
	self.modData = self.javaObject:getModData();
	self.modData.recipe = bcUtils.cloneTable(self.recipe);
	self.modData.recipe.started = true;
	self.modData.recipe.ingredientsAdded = {};
	self.modData.recipe.x = x;
	self.modData.recipe.y = y;
	self.modData.recipe.z = z;
	self.modData.recipe.north = north;
	self.modData.recipe.sprite = sprite;
	self.modData.recipe.data.nSprite = self.nSprite; -- cheating ;)
	for k,v in pairs(self.modData.recipe.ingredients) do
		self.modData.recipe.ingredientsAdded[k] = 0;
	end

	self.javaObject:setOverlaySprite("media/textures/BC_scaffold.png", 1, 1, 1, 1, true);
end -- }}}
function BCCrafTecObject:tryBuild(x, y, z) -- {{{
	-- We're just a 'plan' thingie with little to no effect on the world.
	-- Just place the item...
	-- What could possibly go wrong?
	self:create(x, y, z, self.north, self:getSprite());
end
-- }}}
function BCCrafTecObject:new(recipe) -- {{{
	local o = {};
	setmetatable(o, self);
	self.__index = self;
	o:init();
	o.recipe = recipe;

	local images = BCCrafTec.getImages(getPlayer(), recipe);
	o:setSprite(images.west);
	o:setNorthSprite(images.north);
	o:setEastSprite(images.east);
	o:setSouthSprite(images.south);

	o.name = o.recipe.name;

	o.canBarricade = false;
	o.canPassThrough = true;
	o.blockAllTheSquare = true;
	o.dismantable = false;
	o.renderFloorHelper = recipe.data.renderFloorHelper or false;
	o.canBeAlwaysPlaced = recipe.data.canBeAlwaysPlaced or false;
	o.needToBeAgainstWall = recipe.data.needToBeAgainstWall or false;
	o.isValid = _G[recipe.resultClass].isValid;
	o.noNeedHammer = true; -- do not need a hammer to _start_, but maybe later to _build_

	o.getSquare2Pos = ISWoodenStairs.getSquare2Pos; -- dirty hack :-(
	o.getSquare3Pos = ISWoodenStairs.getSquare3Pos;
	return o;
end -- }}}

function BCCrafTecObject:render(x, y, z, square) -- {{{
	local data = {};
	data.x = x;
	data.y = y;
	data.z = z;
	data.square = square;
	data.done = false;
	triggerEvent("WorldCraftingRender", self, data);
	if data.done then return end

	ISBuildingObject.render(self, x, y, z, square);
	--local sprite = IsoSprite.new()
	--sprite:LoadFramesNoDirPageSimple(self:getModData()["recipe"].sprite)
	--sprite:RenderGhostTile(x, y, z)
end
-- }}}
BCCrafTecObject.renderISDoubleFurniture = function(self, data) -- {{{
	local md = self.recipe;
	if md.resultClass ~= "ISDoubleTileFurniture" then return end;

	local images = BCCrafTec.getImages(getPlayer(), self.recipe);
	for k,v in pairs(images) do
		if not self[k] then
			self[k] = v
		end
	end
	data.done = true;
	ISDoubleTileFurniture.render(self, data.x, data.y, data.z, data.square);
	return;
end
-- }}}
BCCrafTecObject.renderISWoodenStairs = function(self, data) -- {{{
	local md = self.recipe;
	if md.resultClass ~= "ISWoodenStairs" then return end;

	local images = BCCrafTec.getImages(getPlayer(), self.recipe);
	for k,v in pairs(images) do
		if not self[k] then
			self[k] = v
		end
	end
	data.done = true;
	ISWoodenStairs.render(self, data.x, data.y, data.z, data.square);
	return;
end
-- }}}

LuaEventManager.AddEvent("WorldCraftingRender");
Events.WorldCraftingRender.Add(BCCrafTecObject.renderISDoubleFurniture);
Events.WorldCraftingRender.Add(BCCrafTecObject.renderISWoodenStairs);
