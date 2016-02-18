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
	self.modData.recipe = self.recipe;
end -- }}}
function BCCrafTecObject:tryBuild(x, y, z)
	-- We're just a 'plan' thingie with little to no effect on the world.
	-- Just place the item...
	-- What could possibly go wrong?
	self:create(x, y, z);
end
function BCCrafTecObject:new(recipe) -- {{{
	bcUtils.pline("BCCrafTecObject:new()");
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
