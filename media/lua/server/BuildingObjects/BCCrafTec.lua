require "BuildingObjects/ISWoodenWall";
require "bcUtils";

BCCrafTecObject = ISBuildingObject:derive("BCCrafTecObject");

function BCCrafTecObject:create(x, y, z) -- {{{
  local cell = getWorld():getCell();
  self.sq = cell:getGridSquare(x, y, z);

  self.javaObject = IsoThumpable.new(cell, self.sq, 'carpentry_02_56', self.north, self);
  buildUtil.setInfo(self.javaObject, self);
  self.javaObject:setBreakSound("breakdoor");
	self.sq:AddSpecialObject(self.javaObject);

  self.javaObject:transmitCompleteItemToServer();
	self.modData = self.javaObject:getModData();
	self.recipe.started = true;
	self.modData.recipe = self.recipe;
	self.modData.recipe.ingredientsAdded = {};
	for k,v in pairs(self.modData.recipe.ingredients) do
		self.modData.recipe.ingredientsAdded[k] = 0;
	end
end -- }}}
function BCCrafTecObject:tryBuild(x, y, z) -- {{{
	-- We're just a 'plan' thingie with little to no effect on the world.
	-- Just place the item...
	-- What could possibly go wrong?
	self:create(x, y, z);
end
-- }}}
function BCCrafTecObject:new(recipe) -- {{{
	local o = {};
	setmetatable(o, self);
	self.__index = self;
	o:init();
	o.recipe = recipe;
	o.images = {};
	o.images.westSprite   =  recipe.images.west;
	o.images.northSprite  =  recipe.images.north;
	o.images.southSprite  =  recipe.images.south;
	o.images.eastSprite   =  recipe.images.east;

	o:setSprite(o.images.westSprite);
	o:setNorthSprite(o.images.northSprite);
	o:setEastSprite(o.images.eastSprite);
	o:setSouthSprite(o.images.southSprite);

	o.name = recipe.name;
	o.canBarricade = recipe.canBarricade;

	o.canPassThrough = true;
	o.blockAllTheSquare = false;
	o.dismantable = true;
	o.noNeedHammer = true;
	return o;
end -- }}}
function BCCrafTecObject:isValid(square) -- {{{
	if self.recipe.isValid then
		return self.recipe.isValid(self, square);
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
	print(tostring(cell)..", "..tostring(o.sq)..", "..bcUtils.dump(crafTec:getSprite())..", "..tostring(crafTec.north)..", "..tostring(o));
	o.javaObject = IsoThumpable.new(cell, o.sq, crafTec:getSprite(), crafTec.north, o);
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
