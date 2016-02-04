BCCrafTec = ISBuildingObject:derive("BCCrafTec");

function BCCrafTec:createObject(x, y, z, north, sprite) -- {{{
	DirtyWaterServer.pline("BCCrafTec:createObject("..tostring(x)..", "..tostring(y)..", "..tostring(z)..", "..tostring(north)..", "..tostring(sprite)..")");
	local cell = getWorld():getCell();
	self.sq = cell:getGridSquare(x, y, z);

	self.north = north;
	self.sprite = sprite;
	self.x = x;
	self.y = y;
	self.z = z;
	self.javaObject = IsoThumpable.new(cell, self.sq, sprite, north, self);
	buildUtil.setInfo(self.javaObject, self);
	self.javaObject:setMaxHealth(10); -- easy to knock over

	local md = self.javaObject:getModData();
	md["need:DirtyWaterClient.RubberHose"] = 1;
	md["need:DirtyWaterClient.BigFunnel"] = 1;
	md["need:DirtyWaterClient.SwivelGrillStand"] = 1;
	md["need:Base.RoastingPan"] = 1;
	md["need:Base.Pot"] = 1;
	md["dirtyWaterFillLevel"] = 0;
	md["dirtyWaterFillLevelMax"] = 25;

	self.sq:AddTileObject(self.javaObject);
	self.javaObject:transmitCompleteItemToServer();
	
	DirtyWaterServer.pline("BCCrafTec:createObject finished");
end -- }}}
function BCCrafTec:importObject(x, y, z, north, sprite, object) -- {{{
	local cell = getWorld():getCell();
	self.sq = cell:getGridSquare(x, y, z);

	self.north = north;
	self.sprite = sprite;
	self.x = x;
	self.y = y;
	self.z = z;
	self.javaObject = object;

	self:changeSprite(); -- needed to force sprite update
end -- }}}
function BCCrafTec:fromModData(src) -- {{{
	local md = self.javaObject:getModData();

	DirtyWaterServer.pline("BCCrafTec:fromModData("..DirtyWaterServer.dump(src)..")");
	for k,v in pairs(src) do
		md[k] = v
	end

	self.east = src.east;
	self.west = src.west;
	self.north = src.north;
	self.south = src.south;
end -- }}}
function BCCrafTec:toModData(dst) -- {{{
	local md = self.javaObject:getModData();

	for k,v in pairs(md) do
		dst[k] = v
	end

	dst.east = self.east;
	dst.west = self.west;
	dst.north = self.north;
	dst.south = self.south;
end -- }}}
function BCCrafTec:create(x, y, z, north, sprite) -- {{{
	DirtyWaterServer.pline("BCCrafTec:create("..tostring(x)..", "..tostring(y)..", "..tostring(z)..", "..tostring(north)..", "..tostring(sprite)..")");
	self:createObject(x, y, z, north, sprite);
	self.modData = self.javaObject:getModData();
	buildUtil.consumeMaterial(self);
	self.modData = nil;
	local md = {};
	self:toModData(md);
	local args = { x = x, y = y, z = z, north = north, sprite = sprite, modData = md }
	if isClient() then
		sendClientCommand(self.character, 'dirtywater', 'addSimpleStill', args)
	else
		DirtyWaterServer.addSimpleStill(args);
	end

	DirtyWaterServer.pline("BCCrafTec:create finished");
end -- }}}
function BCCrafTec:sendUpdateToServer() -- {{{
	local md = {};
	self:toModData(md);
	local args = { x = self.x, y = self.y, z = self.z, north = self.north, sprite = self.sprite, modData = md }
	if isClient() then
		sendClientCommand(self.character, 'dirtywater', 'addSimpleStill', args)
	else
		DirtyWaterServer.addSimpleStill(args);
	end
end -- }}}

function BCCrafTec:new() -- {{{
	DirtyWaterServer.pline("BCCrafTec:new()");
	local o = {};
	setmetatable(o, self);
	self.__index = self;
	o:init();
	o.sprites = {};
	o.sprites.westSprite = "media/textures/destill1a_east-west.png";
	o.sprites.northSprite = "media/textures/destill1a_south-north.png";
	o.sprites.southSprite = "media/textures/destill1a_north-south.png";
	o.sprites.eastSprite = "media/textures/destill1a_west-east.png";

	o:setSprite(o.sprites.westSprite);
	o:setNorthSprite(o.sprites.northSprite);
	o:setEastSprite(o.sprites.eastSprite);
	o:setSouthSprite(o.sprites.southSprite);
	o.canPassThrough = false;
	o.blockAllTheSquare = true;
	o.dismantable = true;
	o.noNeedHammer = true;
	o.name = "SimpleStill";

	DirtyWaterServer.pline("BCCrafTec:new finished");
	return o;
end -- }}}

function BCCrafTec:isValid(square) -- {{{
	local campfire = camping.findCampfireObject(square);
	if campfire == nil then
		return false -- only build on top of campfires
	end
	local items = square:getObjects();
	for i=0,items:size()-1 do
		if items:get(i):getName() == "SimpleStill" then return false end -- Don't build more than one still on a square
	end
	return true
end -- }}}

function BCCrafTec:changeSprite() -- {{{
	if self.javaObject == nil then return end;

	local newSprite = nil;
	if self.west then newSprite = self.sprites.westSprite; end
	if self.north then newSprite = self.sprites.northSprite; end
	if self.east then newSprite = self.sprites.eastSprite; end
	if self.south then newSprite = self.sprites.southSprite; end

	if newSprite == nil then return end
	-- For some reason this doesn't work and I don't know why :( TODO
	self.javaObject:setSprite(newSprite);
	self.javaObject:transmitUpdatedSpriteToClients();
end -- }}}

function BCCrafTec:render(x, y, z, square) -- {{{
	ISBuildingObject.render(self, x, y, z, square)
end -- }}}

function BCCrafTec.onDestroy(thump, player) -- {{{
	local args = { x = self.x, y = self.y, z = self.z }
	if isClient() then
		sendClientCommand(self.character, 'dirtywater', 'removeSimpleStill', args)
	else
		DirtyWaterServer.removeSimpleStill(args);
	end
	ISBuildingObject.onDestroy(thump, player);
end -- }}}
