require "BuildingObjects/ISBuildUtil";
require "BuildingObjects/ISWoodenWall";
require "bcUtils";

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

BCCrafTecObject = ISBuildingObject:derive("BCCrafTecObject");
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
	o.isValidFunc = recipe.isValid;
	o.recipe = recipe;

	o:setSprite(o.recipe.images.west);
	o:setNorthSprite(o.recipe.images.north);
	o:setEastSprite(o.recipe.images.east);
	o:setSouthSprite(o.recipe.images.south);

	o.name = o.recipe.name;

	o.canBarricade = false;
	o.canPassThrough = true;
	o.blockAllTheSquare = true;
	o.dismantable = false;
	o.noNeedHammer = true; -- do not need a hammer to _start_, but maybe later to _build_
	return o;
end -- }}}
function BCCrafTecObject:isValid(square) -- {{{
	return true;
end -- }}}

--[[
local copyData = function(javaObject, dst) -- {{{
	local md = javaObject:getModData();
	dst.name = md.recipe.name or dst.name;

	for k,v in pairs(md.recipe.data) do
		if k ~= "modData" then
			if type(v) == "table" then
				dst[k] = bcUtils.cloneTable(v);
			else
				dst[k] = v;
			end
		end
	end
end
-- }}}
local copyModData = function(javaObject, dst) -- {{{
	local md = javaObject:getModData();
	local dmd = dst.javaObject:getModData();
	for part,amount in pairs(md.recipe.ingredients) do
		dmd["need:"..part] = amount;
	end

	for k,v in pairs(md.recipe.data.modData) do
		if type(v) == "table" then
			dmd[k] = bcUtils.cloneTable(v);
		else
			dmd[k] = v;
		end
	end

	dst:getSprite(); -- sets sprite, north, west, south and east values
end
-- }}}
function BCCrafTecObject.createFromCrafTec(crafTec, character)--{{{
	local md = crafTec:getModData()["recipe"];

	local o = ISWoodenContainer:new(md.images.west, md.images.north);
	o:setEastSprite(md.images.east);
	o:setSouthSprite(md.images.south);

	local x = crafTec:getSquare():getX();
	local y = crafTec:getSquare():getY();
	local z = crafTec:getSquare():getZ();

	local cell = getWorld():getCell();
	o.sq = cell:getGridSquare(x, y, z);

	o.player = character;
	copyData(crafTec, o);

	local saveFunc = buildUtil.consumeMaterial;
	buildUtil.consumeMaterial = function() end
	o:create(x, y, z, md.north, o.sprite);
	buildUtil.consumeMaterial = saveFunc;

	copyModData(crafTec, o);
	return o;
end
--}}}
function ISWoodenWall.createFromCrafTec(crafTec, character)--{{{
	local md = crafTec:getModData()["recipe"];

	local o = ISWoodenWall:new(md.images.west, md.images.north, crafTec.corner);

	local x = crafTec:getSquare():getX();
	local y = crafTec:getSquare():getY();
	local z = crafTec:getSquare():getZ();

	local cell = getWorld():getCell();
	o.sq = cell:getGridSquare(x, y, z);

	o.player = character;
	o.javaObject = IsoThumpable.new(cell, o.sq, md.sprite, md.north, o);
	crafTec:copyData(o);
	buildUtil.setInfo(o.javaObject, o);
	o.javaObject:setMaxHealth(o:getHealth());
	o.javaObject:setBreakSound("breakdoor");
	buildUtil.addWoodXp(o);
	o.sq:AddSpecialObject(o.javaObject);
	o.sq:RecalcAllWithNeighbours(true);
	o.javaObject:transmitCompleteItemToServer();
	if o.sq:getZone() then
		o.sq:getZone():setHaveConstruction(true);
	end
	return o;
end
--}}}
function ISSimpleFurniture.createFromCrafTec(crafTec, character)--{{{
	local md = crafTec:getModData()["recipe"];

	local o = ISSimpleFurniture:new(md.name, md.images.west, md.images.north);
	o:setEastSprite(sprite.eastSprite);
	o:setSouthSprite(sprite.southSprite);

	local x = crafTec:getSquare():getX();
	local y = crafTec:getSquare():getY();
	local z = crafTec:getSquare():getZ();

	local cell = getWorld():getCell();
	o.sq = cell:getGridSquare(x, y, z);

	o.player = character;
	o.javaObject = IsoThumpable.new(cell, o.sq, md.sprite, md.north, o);
	crafTec:copyData(o);
	buildUtil.setInfo(o.javaObject, o);
	o.javaObject:setMaxHealth(o:getHealth());
	o.javaObject:setBreakSound("breakdoor");
	buildUtil.addWoodXp(o);
	o.sq:AddSpecialObject(o.javaObject);
	o.javaObject:transmitCompleteItemToServer();
	return o;
end
--}}}
function ISLightSource.createFromCrafTec(crafTec, character)--{{{
	local md = crafTec:getModData()["recipe"];

	local o = ISWoodenContainer:new(md.images.west, md.images.north, getSpecificPlayer(character));
	o:setEastSprite(sprite.eastSprite);
	o:setSouthSprite(sprite.southSprite);

	local x = crafTec:getSquare():getX();
	local y = crafTec:getSquare():getY();
	local z = crafTec:getSquare():getZ();

	local cell = getWorld():getCell();
	o.sq = cell:getGridSquare(x, y, z);

	o.player = character;
	o.javaObject = IsoThumpable.new(cell, o.sq, md.sprite, md.north, o);
	crafTec:copyData(o);
	buildUtil.setInfo(o.javaObject, o);
	local offX = o.offsetX;
	local offY = o.ofysetY;
	if o.west then offX = -offX; end
	if o.north then offY = -offY; end
	o.javaObject:createLightSource(o.radius, offX, offY, 0, 0, o.fuel, o.character:getInventory():FindAndReturn(self.baseItem), o.character); -- TODO

	o.javaObject:setMaxHealth(o:getHealth());
	o.javaObject:setBreakSound("breakdoor");
	buildUtil.addWoodXp(o);
	o.sq:AddSpecialObject(o.javaObject);
	o.javaObject:transmitCompleteItemToServer();
	return o;
end
--}}}
function RainCollectorBarrel.createFromCrafTec(crafTec, character)--{{{
	local md = crafTec:getModData()["recipe"];

	local o = RainCollectorBarrel:new(charactel, md.images.west, crafTec.data.waterMax);

	local x = crafTec:getSquare():getX();
	local y = crafTec:getSquare():getY();
	local z = crafTec:getSquare():getZ();

	local cell = getWorld():getCell();
	o.sq = cell:getGridSquare(x, y, z);

	o.player = character;
	o.javaObject = IsoThumpable.new(cell, o.sq, md.sprite, md.north, o);
	crafTec:copyData(o);
	buildUtil.setInfo(o.javaObject, o);
	o.javaObject:setMaxHealth(o:getHealth());
	o.javaObject:setBreakSound("breakdoor");
	buildUtil.addWoodXp(o);
	o.sq:AddSpecialObject(o.javaObject);
	o.javaObject:transmitCompleteItemToServer();
	return o;
end
--}}}
--]]
