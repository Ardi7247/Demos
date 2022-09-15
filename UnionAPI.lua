local cleanup = Instance.new("Folder",game.ReplicatedStorage)

local UnionAPI = {}
UnionAPI.__index = UnionAPI
UnionAPI.UnionDictionary = {} -- Make a dictionary to store KV pairs for indexing union data

function UnionAPI.GetInfo(Part)
	assert(Part:IsA('BasePart'),'Instance is not a part!')
	if UnionAPI.UnionDictionary[Part] ~= nil then
		return UnionAPI.UnionDictionary[Part]
	else
		return 'Part has no saved UnionInfo!'
	end
end

function UnionAPI.new(Type,GroupA,GroupB)
	
	local ValidTypes = {
		['Add'] = true;
		['Subtract'] = true;
		['Intersect'] = true; 
	} -- Assign valid types for new unions
	
	assert(ValidTypes[Type], 'Invalid Union type!')
	--Check to make sure the selected Type for the union is a valid 
	local function formatUnion(A,B) --Function to prepare for CSG of groups
		if #A>=2 then
			local target = A[1]
			target.Parent = cleanup
			table.remove(A,1)
			if target:IsA('BasePart') then
				A = {target:UnionAsync(A)}
			end
		end
		if #B>=2 then
			local target = B[1]
			target.Parent = cleanup
			table.remove(B,1)
			if target:IsA('BasePart') then
				B = {target:UnionAsync(B)}
			end
		end
		return A,B
	end
	local Operations = {
		['Add'] = function(A,B)
			local Af, Bf = formatUnion(A,B)
			local result = Af[1]:UnionAsync(Bf)
			return result
		end;
		['Subtract'] = function(A,B)
			local Af, Bf = formatUnion(A,B)
			local result = Af[1]:SubtractAsync(Bf)
			return result
		end;
		['Intersect'] = function(A,B)
			local Af, Bf = formatUnion(A,B)
			local APart = Instance.new('Part')
			APart.Anchored = true
			APart.Size = Vector3.new(2048,2048,2048)
			APart.Position = Af[1].Position
			APart.Parent = cleanup
			local AInv = APart:SubtractAsync(Af)
			AInv.Parent = cleanup
			
			local BPart = Instance.new('Part')
			BPart.Anchored = true
			BPart.Size = Vector3.new(2048,2048,2048)
			BPart.Position = Bf[1].Position
			BPart.Parent = cleanup
			local BInv = BPart:SubtractAsync(Bf)
			BInv.Parent = cleanup
			
			local CPart = Instance.new('Part')
			CPart.Anchored = true
			CPart.Position = Vector3.new((APart.Position.X+BPart.Position.X)/2,(APart.Position.Y+BPart.Position.Y)/2,(APart.Position.Z+BPart.Position.Z)/2)
			CPart.Size = Vector3.new(2047-math.abs(APart.Position.X-BPart.Position.X),2047-math.abs(APart.Position.Y-BPart.Position.Y),2047-math.abs(APart.Position.Z-BPart.Position.Z))
			CPart.Parent = cleanup
			local DPart = CPart:SubtractAsync({BInv})
			DPart.Parent = cleanup
			local EPart = DPart:SubtractAsync({AInv})
			for _, v in pairs(cleanup:GetChildren()) do
				v:Destroy()
			end
			return EPart
		end;
	} -- Assign functions to each type of operation
	
	local self = setmetatable({},UnionAPI)
	
	self.GroupA = GroupA
	self.GroupB = GroupB
	self.result = Operations[Type](GroupA,GroupB)
	UnionAPI.UnionDictionary[self.result] = {Type, GroupA, GroupB}
	for _, v in pairs(GroupA) do
		if v:IsA("Instance") then
			v:Destroy()
		end
	end
	for _, v in pairs(GroupB) do
		if v:IsA("Instance") then
			v:Destroy()
		end
	end
	GroupA = nil
	GroupB = nil
	self.result.Parent = workspace
	self.result.UsePartColor = true
	
	return self
end



return UnionAPI
