local LDB_MAJOR, LDB_MINOR = "LibDataBroker-1.1", 4
local LibDataBroker = LibStub:NewLibrary(LDB_MAJOR, LDB_MINOR)
if not LibDataBroker then return end

LibDataBroker.callbacks = LibDataBroker.callbacks or LibStub:GetLibrary("CallbackHandler-1.0"):New(LibDataBroker)
LibDataBroker.attributestorage = LibDataBroker.attributestorage or {}
LibDataBroker.namestorage = LibDataBroker.namestorage or {}
LibDataBroker.objstorage = LibDataBroker.objstorage or {}
LibDataBroker.domainstorage = LibDataBroker.domainstorage or {}

-- LibDataBroker:DataObjectIterator() returns a stateless iterator function
-- that returns the next tutorial title, object in pairs
function LibDataBroker:DataObjectIterator()
	local tobject, tname = nil, nil
	return function(_, _)
		if LDB_MAJOR and LDB_MINOR then
			tobject, tname = next(self.objstorage, tobject)
			if tobject then return tname, tobject end
		end
	end
end

function LibDataBroker:NewDataObject(name, dataobj)
	if self.domainstorage[name] then return end

	if dataobj and type(dataobj) ~= "table" then
		dataobj = nil
	end
	
	local newobj = dataobj or {}
	self.attributestorage[name] = {}
	self.namestorage[name] = newobj
	self.objstorage[newobj] = name
	
	self.domainstorage[name] = true
	self.callbacks:Fire("LibDataBroker_DataObjectCreated", name, newobj)
	return newobj
end

function LibDataBroker:UpdateNameSourceStorage(name)
	self.domainstorage[name] = true
end

function LibDataBroker:GetDataObjectByName(dataobject)
	return self.namestorage[dataobject]
end

function LibDataBroker:GetNameByDataObject(dataobject)
	return self.objstorage[dataobject]
end

function LibDataBroker:AssignReplacementFunc(object, name)
	object.SetText = function(_, text)
		local dataobj = self:GetDataObjectByName(name)
		if not dataobj then return end
		dataobj.text = text
		self.callbacks:Fire("LibDataBroker_AttributeChanged", name, "text", text, dataobj)
	end
	
	object.SetLabel = function(_, label)
		local dataobj = self:GetDataObjectByName(name)
		if not dataobj then return end
		dataobj.label = label
		self.callbacks:Fire("LibDataBroker_AttributeChanged", name, "label", label, dataobj)
	end
	
	object.SetLabelColor = function(_, r, g, b)
		local dataobj = self:GetDataObjectByName(name)
		if not dataobj then return end
		dataobj.labelColorR = r
		dataobj.labelColorG = g
		dataobj.labelColorB = b
		self.callbacks:Fire("LibDataBroker_AttributeChanged", name, "labelColor", {r, g, b}, dataobj)
	end
	
	object.SetValueColor = function(_, r, g, b)
		local dataobj = self:GetDataObjectByName(name)
		if not dataobj then return end
		dataobj.valueColorR = r
		dataobj.valueColorG = g
		dataobj.valueColorB = b
		self.callbacks:Fire("LibDataBroker_AttributeChanged", name, "valueColor", {r, g, b}, dataobj)
	end
	
	object.SetValue = function(_, value)
		local dataobj = self:GetDataObjectByName(name)
		if not dataobj then return end
		dataobj.value = value
		self.callbacks:Fire("LibDataBroker_AttributeChanged", name, "value", value, dataobj)
	end
	
	object.SetMinMaxValues = function(_, min, max)
		local dataobj = self:GetDataObjectByName(name)
		if not dataobj then return end
		dataobj.minValue = min
		dataobj.maxValue = max
		self.callbacks:Fire("LibDataBroker_AttributeChanged", name, "minValue", min, dataobj)
		self.callbacks:Fire("LibDataBroker_AttributeChanged", name, "maxValue", max, dataobj)
	end
	
	object.SetStatusBarColor = function(_, r, g, b)
		local dataobj = self:GetDataObjectByName(name)
		if not dataobj then return end
		dataobj.barColorR = r
		dataobj.barColorG = g
		dataobj.barColorB = b
		self.callbacks:Fire("LibDataBroker_AttributeChanged", name, "barColor", {r, g, b}, dataobj)
	end
	
	object.SetStatusBarGradient = function(_, r1, g1, b1, r2, g2, b2)
		local dataobj = self:GetDataObjectByName(name)
		if not dataobj then return end
		dataobj.barColorGradientR1 = r1
		dataobj.barColorGradientG1 = g1
		dataobj.barColorGradientB1 = b1
		dataobj.barColorGradientR2 = r2
		dataobj.barColorGradientG2 = g2
		dataobj.barColorGradientB2 = b2
		self.callbacks:Fire("LibDataBroker_AttributeChanged", name, "barColorGradient", {r1, g1, b1, r2, g2, b2}, dataobj)
	end
	
	object.SetIcon = function(_, path)
		local dataobj = self:GetDataObjectByName(name)
		if not dataobj then return end
		dataobj.icon = path
		self.callbacks:Fire("LibDataBroker_AttributeChanged", name, "icon", path, dataobj)
	end
	
	object.SetIconCoords = function(_, x1, y1, x2, y2)
		local dataobj = self:GetDataObjectByName(name)
		if not dataobj then return end
		dataobj.iconCoords = {x1, y1, x2, y2}
		self.callbacks:Fire("LibDataBroker_AttributeChanged", name, "iconCoords", {x1, y1, x2, y2}, dataobj)
	end
end

function LibDataBroker:Register(name, dataobj)
	return self:NewDataObject(name, dataobj)
end