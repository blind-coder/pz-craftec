require "TimedActions/ISBaseTimedAction"

BCCrafTecTA = ISBaseTimedAction:derive("BCCrafTecTA");
BCCrafTecTA.worldCraftingFinished = function(object, character, retVal) -- {{{
	if retVal.object then return end; -- might be overriden by another event

	local md = object:getModData()["recipe"];
	local o;

	if md.resultClass == "ISLightSource" then
		o = ISLightSource:new(md.images.west, md.images.north, character);
	elseif md.resultClass == "ISSimpleFurniture" then
		o = ISSimpleFurniture:new(md.name, md.images.west, md.images.north);
	elseif md.resultClass == "ISWoodenContainer" then
		o = ISWoodenContainer:new(md.images.west, md.images.north);
	elseif md.resultClass == "ISWoodenDoorFrame" then
		o = ISWoodenDoorFrame:new(md.images.west, md.images.north, md.images.corner);
	elseif md.resultClass == "ISWoodenDoor" then
		o = ISWoodenDoor:new(md.images.west, md.images.north, md.images.open, md.images.openNorth);
	elseif md.resultClass == "ISWoodenFloor" then
		o = ISWoodenFloor:new(md.images.west, md.images.north);
	elseif md.resultClass == "ISWoodenWall" then
		o = ISWoodenWall:new(md.images.west, md.images.north, md.images.corner);
	elseif md.resultClass == "RainCollectorBarrel" then
		o = RainCollectorBarrel:new(character, md.images.west, md.data.waterMax);
	elseif md.resultClass == "ISWoodenStairs" then
		o = ISWoodenStairs:new(md.images.sprite1, md.images.sprite2, md.images.sprite3, md.images.northSprite1, md.images.northSprite2, md.images.northSprite3, md.images.pillar, md.images.pillarNorth)
	elseif md.resultClass == "ISDoubleTileFurniture" then
		o = ISDoubleTileFurniture:new(md.name, md.images.sprite1, md.images.sprite2, md.images.northSprite1, md.images.northSprite2)
	end

	retVal.object = o;
end
-- }}}

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
local createRealObjectFromCrafTec = function(crafTec, character)--{{{
  local md = crafTec:getModData()["recipe"];
	local retVal = {};

	triggerEvent("OnWorldCraftingFinished", crafTec, character, retVal);

	o = retVal.object;
  o:setSprite(md.images.west);
  o:setNorthSprite(md.images.north);
  o:setEastSprite(md.images.east);
  o:setSouthSprite(md.images.south);

  local x = crafTec:getSquare():getX();
  local y = crafTec:getSquare():getY();
  local z = crafTec:getSquare():getZ();

  local cell = getWorld():getCell();
  o.sq = cell:getGridSquare(x, y, z);

  o.player = character;
  copyData(crafTec, o);
	o.sprite = o:getSprite(); -- copyData sets nSprite (added in BCCrafTecObject:create), so this sets .sprite and the north, east, south and west options

  local saveFunc = buildUtil.consumeMaterial;
  buildUtil.consumeMaterial = function() end
  o:create(x, y, z, o.north, o.sprite);
  buildUtil.consumeMaterial = saveFunc;

  copyModData(crafTec, o);
  return o;
end
--}}}

function BCCrafTecTA:isValid(square, north) -- {{{
	return true;
end
-- }}}
function BCCrafTecTA:update() -- {{{
	-- TODO make more performant
	if self.stopped then return end;
	local modData = self.object:getModData()["recipe"];
	local prof = self.character:getDescriptor():getProfession();

	local maxPartsProgress = 100;
	for part,amount in pairs(modData.ingredients) do
		local avail = (modData.ingredientsAdded and modData.ingredientsAdded[part]) or 0;
		maxPartsProgress = math.min(avail*100/amount, maxPartsProgress);
	end

	local canProgress = false;
	for k,profession in pairs(modData.requirements) do
		if (not canProgress) and ((k == prof) or (k == "any")) then
			for k2,skill in pairs(profession) do
				if (not canProgress)
						and (skill.progress < skill.time)
						and (skill.progress < skill.time / (100 / maxPartsProgress))
						and (
							(k2 == "any")
							or self.character:getPerkLevel(Perks.FromString(k2)) >= skill.level
						)
					then
					canProgress = skill;
				end
			end
		end
	end

	local haveAllTools = true;
	for _,tools in pairs(modData.tools or {}) do
		local haveOneTool = false;
		for _,tool in pairs(bcUtils.split(tools, "/")) do
			if self.character:getInventory():FindAndReturn(tool) then
				haveOneTool = true;
			end
		end
		if (haveAllTools) and (not haveOneTool) then
			haveAllTools = false;
		end
	end

	if not haveAllTools then
		self.character:Say("I don't have the required tools.");
		self:stop();
		return;
	end

	if not canProgress then
		if maxPartsProgress < 100 then
			self.character:Say("I don't have the necessary parts.");
		else
			self.character:Say("I don't have the necessary skills.");
		end
		self:stop();
		return;
	end

	local timeHours = getGameTime():getTimeOfDay();
	if not self.lastCheck then self.lastCheck = timeHours; end
	if timeHours < self.lastCheck then timeHours = timeHours + 24 end
	local elapsedMins = (timeHours - self.lastCheck) * 60
	local progress = math.floor(elapsedMins + 0.0001)
	if progress > 0 then
		self.lastCheck = timeHours;
		canProgress.progress = math.min(canProgress.progress + progress, canProgress.time);
	end

	if canProgress.progress >= canProgress.time then
		self:checkIfFinished();
	end
end
-- }}}
function BCCrafTecTA:start() -- {{{
	--TODO: set job delta for any required tools
	--self.object:setJobType('CrafTec '.. self.object:getModData()["CrafTec"]["product"]);
	--self.object:setJobDelta(0.0);
	self.startTimeHours = getGameTime():getTimeOfDay()
	self.lastCheck = self.startTimeHours;
end
-- }}}
function BCCrafTecTA:stop() -- {{{
	-- TODO: remove ourselves from the queue properly
	if self.stopped then return end;
	ISBaseTimedAction.stop(self);
	self.stopped = true;
	self:checkIfFinished();
end
-- }}}
function BCCrafTecTA:perform() -- {{{
	self:checkIfFinished();
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end
-- }}}
function BCCrafTecTA:checkIfFinished() -- {{{
	if not self.object then return end

	local modData = self.object:getModData()["recipe"];

	for k,skills in pairs(modData.requirements) do
		for k2,s in pairs(skills) do
			if s.progress < s.time then
				return;
			end
		end
	end

	local result = createRealObjectFromCrafTec(self.object, self.player);

	local sq = self.object:getSquare();
	if isClient() then
		sq:transmitRemoveItemFromSquare(self.object);
	end
	sq:RemoveTileObject(self.object);

	self.object = nil;
	if not self.stopped then
		self:stop();
	end
end
-- }}}
function BCCrafTecTA:calculateMaxTime() -- {{{
	local requirements = self.object:getModData()["recipe"]["requirements"];
	local retVal = 1;

	for _,p in pairs(requirements) do
		for _,v in pairs(p) do
			if not v.progress then v.progress = 0; end
			retVal = retVal + v.time - v.progress;
		end
	end

	local f = 1 / getGameTime():getMinutesPerDay() / 2;
	retVal = retVal / f; -- taken from ISReadABook, not sure why it's this way

	return retVal;
end
-- }}}
function BCCrafTecTA:new(character, object) -- {{{
	local modData = object:getModData();
	if not modData.recipe then
		getSpecificPlayer(character):Say("BUG CRAFTEC001: object has no modData.recipe");
		return false;
	end

	local o = {}

	setmetatable(o, self)
	self.__index = self
	o.character = getSpecificPlayer(character);
	o.player = character;
	o.object = object;
	o.stopOnWalk = true;
	o.stopOnRun = true;
	o.stopped = false;

	o.maxTime = o:calculateMaxTime();
	return o;
end
-- }}}

LuaEventManager.AddEvent("OnWorldCraftingFinished");
Events.OnWorldCraftingFinished.Add(BCCrafTecTA.worldCraftingFinished);

BCCrafTecDeconTA = ISBaseTimedAction:derive("BCCrafTecDeconTA");
function BCCrafTecDeconTA:isValid(square, north) -- {{{
	return true;
end
-- }}}
function BCCrafTecDeconTA:update() -- {{{
	-- TODO make more performant
	if self.stopped then return end;
	local modData = self.object:getModData()["recipe"];
	local prof = self.character:getDescriptor():getProfession();

	local sum = 0;
	local canProgress = false;
	for k,profession in pairs(modData.requirements) do
		if (not canProgress) and ((k == prof) or (k == "any")) then
			for k2,skill in pairs(profession) do
				sum = skill.progress + sum;
				if (not canProgress) and (skill.progress > 0) then
					canProgress = skill;
				end
			end
		end
	end

	if not canProgress and sum > 0 then
		self.character:Say("I don't have the necessary skills.");
		self:stop();
		return;
	end

	local timeHours = getGameTime():getTimeOfDay();
	if not self.lastCheck then self.lastCheck = timeHours; end
	if timeHours < self.lastCheck then timeHours = timeHours + 24 end
	local elapsedMins = (timeHours - self.lastCheck) * 60
	local progress = math.floor(elapsedMins + 0.0001)
	if progress > 0 then
		self.lastCheck = timeHours;
		canProgress.progress = math.max(0, canProgress.progress - progress);
	end

	if canProgress and canProgress.progress <= 0 then
		self:checkIfFinished();
	end
end
-- }}}
function BCCrafTecDeconTA:start() -- {{{
	self.startTimeHours = getGameTime():getTimeOfDay()
	self.lastCheck = self.startTimeHours;
end
-- }}}
function BCCrafTecDeconTA:stop() -- {{{
	-- TODO: remove ourselves from the queue properly
	if self.stopped then return end;
	ISBaseTimedAction.stop(self);
	self.stopped = true;
	self:checkIfFinished();
end
-- }}}
function BCCrafTecDeconTA:perform() -- {{{
	self:checkIfFinished();
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end
-- }}}
function BCCrafTecDeconTA:checkIfFinished() -- {{{
	if not self.object then return end

	local modData = self.object:getModData()["recipe"];

	for k,skills in pairs(modData.requirements) do
		for k2,s in pairs(skills) do
			if s.progress > 0 then
				return;
			end
		end
	end

	local sq = self.object:getSquare();
	for part,amount in pairs(modData.ingredientsAdded) do
		for i=0,amount-1 do
			sq:AddWorldInventoryItem(part, 0, 0, 0);
		end
	end

	if isClient() then
		sq:transmitRemoveItemFromSquare(self.object);
	end
	sq:RemoveTileObject(self.object);

	self.object = nil;
	if not self.stopped then
		self:stop();
	end
end
-- }}}
function BCCrafTecDeconTA:calculateMaxTime() -- {{{
	local requirements = self.object:getModData()["recipe"]["requirements"];
	local retVal = 1;

	for _,p in pairs(requirements) do
		for _,v in pairs(p) do
			if not v.progress then v.progress = 0; end
			retVal = retVal + v.progress;
		end
	end

	local f = 1 / getGameTime():getMinutesPerDay() / 2;
	retVal = retVal / f; -- taken from ISReadABook, not sure why it's this way

	return retVal;
end
-- }}}
function BCCrafTecDeconTA:new(character, object) -- {{{
	local modData = object:getModData();
	if not modData.recipe then
		getSpecificPlayer(character):Say("BUG CRAFTEC001: object has no modData.recipe");
		return false;
	end

	local o = {}

	setmetatable(o, self)
	self.__index = self
	o.character = getSpecificPlayer(character);
	o.player = character;
	o.object = object;
	o.stopOnWalk = true;
	o.stopOnRun = true;
	o.stopped = false;

	o.maxTime = o:calculateMaxTime();
	return o;
end
-- }}}
