require "BuildingObjects/ISWoodenWall";
require "bcUtils";

BCCrafTecObject = ISBuildingObject:derive("BCCrafTecObject");

function BCCrafTecObject:create(x, y, z, north, sprite) -- {{{
  local cell = getWorld():getCell();
  self.sq = cell:getGridSquare(x, y, z);

  self.javaObject = IsoThumpable.new(cell, self.sq, --[[sprite,]] 'media/textures/BC_scaffold', north, self);
  buildUtil.setInfo(self.javaObject, self);
  self.javaObject:setBreakSound("breakdoor");
	self.sq:AddSpecialObject(self.javaObject);

  self.javaObject:transmitCompleteItemToServer();
	self.modData = self.javaObject:getModData();
	self.modData.recipe = bcUtils.cloneTable(self.recipe);
	-- self.recipe = nil;
	self.modData.recipe.started = true;
	self.modData.recipe.ingredientsAdded = {};
	self.modData.recipe.x = x;
	self.modData.recipe.y = y;
	self.modData.recipe.z = z;
	self.modData.recipe.north = north;
	self.modData.recipe.sprite = sprite;
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
	o.recipe = bcUtils.cloneTable(recipe);
	o.images = {};
	o.images.westSprite  = o.recipe.images.west;
	o.images.northSprite = o.recipe.images.north;
	o.images.southSprite = o.recipe.images.south;
	o.images.eastSprite  = o.recipe.images.east;

	o:setSprite(o.images.westSprite);
	o:setNorthSprite(o.images.northSprite);
	o:setEastSprite(o.images.eastSprite);
	o:setSouthSprite(o.images.southSprite);

	o.name = o.recipe.name;
	o.canBarricade = o.recipe.canBarricade;

	o.canPassThrough = true;
	o.blockAllTheSquare = false;
	o.dismantable = false;
	o.noNeedHammer = true;
	return o;
end -- }}}
function BCCrafTecObject:isValid(square) -- {{{
	if self.isValidFunc then
		return self.isValidFunc(self, square);
	end
	return true;
end -- }}}

--[[ Needed? -- {{{
function BCCrafTecObject:render(x, y, z, square)
	ISBuildingObject.render(self, x, y, z, square)
end
--}}} ]]

function ISWoodenWall.createFromCrafTec(crafTec, character)
	local md = crafTec:getModData()["recipe"];

	local o = ISWoodenWall:new(md.images.east, md.images.north, crafTec.corner);

	local x = crafTec:getSquare():getX();
	local y = crafTec:getSquare():getY();
	local z = crafTec:getSquare():getZ();

	local cell = getWorld():getCell();
	o.sq = cell:getGridSquare(x, y, z);

	o.player = character;
	o.javaObject = IsoThumpable.new(cell, o.sq, md.sprite, md.north, o);
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
end
