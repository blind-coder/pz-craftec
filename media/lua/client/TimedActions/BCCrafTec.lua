require "TimedActions/ISBaseTimedAction"

--[[
--{{{
--ModData used:
--CrafTec: Object containing modData for CrafTecs with following attributes:
--  product: contains getFullType (e.g.: "Base.Axe") of finished product
--  requirements: Object containing requirements of Skills and Professions, e.g.:
--    Elecrician:
--      any: {level: 0, time: 100, progress: 10} -- any electrician can do this and take 100 minutes and already 10 minutes done
--    Engineer:
--      Carpentry: {level: 2, time: 200} -- any Engineer with Carpentry at least level 2 can do this and take 200 minutes and no units done
--    any:
--      Foraging: {level: 4, time: 0} -- any player with Foraging at least level 4 can do this regardless of profession and be finished immediately
--    any:
--      any: {level: 0, time: 500} -- anyone can do this in 500 minutes
--      -- actually, any: {level: >0} doesn't make sense and will be ignored.
--
--As of Build 32.03 the following Perks are available:
--  Agility, Cooking, Melee, Crafting, Fitness, Strength, Blunt, Axe, Sprinting, Lightfoot, Nimble, Sneak, Woodwork, Aiming, Reloading, Farming, Survivalist, Fishing, Trapping, Passiv, Firearm, PlantScavenging, BluntParent, BladeParent, BluntGuard, BladeGuard, BluntMaintenance, BladeMaintenance, Doctor, Electricity
--
-- }}}
--]]

BCCrafTec = ISBaseTimedAction:derive("BCCrafTec");
function BCCrafTec:isValid() -- {{{
	if self.item and self.character then
		return self.character:getInventory():contains(self.item);
	end
	return false;
end
-- }}}

function BCCrafTec:update() -- {{{
	local modData = self.item:getModData()["CrafTec"];
	local canProgress = false;
	local prof = self.character:getDescriptor():getProfession();

	self.item:setJobDelta(self:getJobDelta());

	for k,profession in pairs(modData["requirements"]) do
		if (not canProgress) and ((k == prof) or (k == "any")) then
			for k2,skill in pairs(profession) do
				if (not canProgress) and (skill["progress"] < skill["time"]) and ((k2 == "any") or self.character:getPerkLevel(Perk.FromString(k2)) >= skill["level"]) then
					canProgress = skill;
				end
			end
		end
	end

	if not canProgress then
		self.character:Say("I can't progress on this project.");
		self:stop();
		return;
	end

	local timeHours = getGameTime():getTimeOfDay()
	if not self.lastCheck then self.lastCheck = timeHours; end
	if timeHours < self.lastCheck then timeHours = timeHours + 24 end
	local elapsedMins = (timeHours - self.lastCheck) * 60
	local progress = math.floor(elapsedMins + 0.0001)
	if progress > 0 then
		self.lastCheck = timeHours;
		canProgress["progress"] = math.min(canProgress["progress"] + progress, canProgress["time"]);
	end

	if canProgress["progress"] >= canProgress["time"] then
		self:checkIfFinished();
	end
end
-- }}}

function BCCrafTec:start() -- {{{
	self.item:setJobType('CrafTec '.. self.item:getModData()["CrafTec"]["product"]);
	self.item:setJobDelta(0.0);
	self.startTimeHours = getGameTime():getTimeOfDay()
	self.lastCheck = self.startTimeHours;
end
-- }}}

function BCCrafTec:stop() -- {{{
	ISBaseTimedAction.stop(self);
	if self.item then
		self.item:setJobDelta(0.0);
	end

	self:checkIfFinished();
end
-- }}}

function BCCrafTec:perform() -- {{{
	self.item:getContainer():setDrawDirty(true);
	self.item:setJobDelta(0.0);
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end
-- }}}

function BCCrafTec:checkIfFinished() -- {{{
	if not self.item then return end

	local modData = self.item:getModData()["CrafTec"];

	for k,skills in pairs(modData["requirements"]) do
		for k2,s in pairs(skills) do
			if s["progress"] < s["time"] then
				return;
			end
		end
	end

	local inventory = self.character:getInventory();
	inventory:AddItem(modData["product"]);
	inventory:Remove(self.item);

	self.item = nil;
	self:stop();
end
-- }}}

function BCCrafTec:calculateMaxTime() -- {{{
	local requirements = self.item:getModData()["CrafTec"]["requirements"];
	local retVal = 1;

	for _,p in pairs(requirements) do
		for _,v in pairs(p) do
			retVal = retVal + v["time"] - v["progress"];
		end
	end

	local f = 1 / getGameTime():getMinutesPerDay() / 2;
	retVal = retVal / f; -- taken from ISReadABook, not sure why it's this way

	return retVal;
end
-- }}}

function BCCrafTec:new(character, item, time) -- {{{
	local modData = item:getModData();
	if not modData["CrafTec"] then
		getSpecificPlayer(character):Say("BUG CRAFTEC001: item has no modData['CrafTec']");
		return false;
	end

	local o = {}

	setmetatable(o, self)
	self.__index = self
	o.character = character;
	o.item = item;
	o.stopOnWalk = true;
	o.stopOnRun = true;

	o.maxTime = o:calculateMaxTime();
	return o;
end
-- }}}
