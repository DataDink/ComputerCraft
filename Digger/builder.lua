if (builder == nil) then
	builder = {};
	
	local function round(number)
		if (number % 1 >= 0.5) then
			return math.ceil(number);
		else
			return math.floor(number);
		end
	end

	local plot = function(angle, distance) 
		return {
			h = math.cos(math.rad(angle)) * distance,
			v = math.sin(math.rad(angle)) * distance
		};
	end
	
	local measure = function(h, v, d)
		if (d == nil) then d = 0; end
		return math.sqrt(h*h + v*v + d*d);
	end
	
	local extractClosestVector(from, vectors)
		if (vectors == nil or vectors[1] == nil) then return nil; end
		local result = nil;
		for i, v in pairs(vectors) do
			local dist = measure(v.x - from.x, v.y - from.y, v.z - from.z);
			if (result == nil or dist < result.distance) then
				result = {
					index = i,
					vector = v,
					distance = dist
				};
			end
		end
		return table.remove(vectors, result.index);
	end
	
	local groupBy = function(objects, indexer)
		local byIndex = {};
		for i, v in pairs(objects) do
			local key = indexer(v);
			if (byIndex[key] == nil) then byIndex[key] = {}; end
			table.insert(byIndex[key], v);
		end
		local indexes = {};
		for i in pairs(byIndex) do
			table.insert(indexes, i);
		end
		table.sort(indexes);
		local result = {};
		for i, v in pairs(indexes) do
			table.insert(result, byIndex[v]);
		end
		return result;
	end
	
	local sortVector = function(vectors)
		local result = {};
		local refPoint = {};
		local byZ = groupBy(vectors, function(v) return v.z; end);
		for iz, zvectors in pairs(byZ) do
			local byY = groupBy(zvectors, function(v) return v.y; end);
			for iy, yvectors in pairs(byY) do
				local lastVector = table.remove(yvectors, 1);
				while (lastVector ~= nil) do
					table.insert(result, lastVector);
					lastVector = extractClosestVector(lastVector, yvectors);
				end
			end
		end
		return result;
	end
	
	builder.findInventory = function()
		for i = 2, 16 do
			if (turtle.getItemCount(i) > 0) then
				return i;
			end
		end
		return nil;
	end
	
	builder.placeDown = function()
		if (builder.findInventory() == nil) then
			print("Waiting for inventory");
			while (builder.findInventory() == nil) do
				sleep(1);
			end
			print("Continuing in 15 seconds");
			sleep(15);
		end
		turtle.select(builder.findInventory());
		turtle.placeDown();
	end
	
	builder.circle = function(radius, angleX, angleZ)
		local plots = {};
		local step = 45 / radius;
		if (angleX == nil) then angleX = 0; end
		if (angleZ == nil) then angleZ = 0; end
		for angle = 0, 360, step do
			local fplot = plot(angle, radius);
			local xplot = plot(angleX, fplot.v);
			local nplot = {x = fplot.h, y = xplot.h, z = xplot.v};
			local zplot = {
				x = round(math.cos(math.rad(angleZ)) * nplot.x - math.sin(math.rad(angleZ)) * nplot.y),
				y = round(math.sin(math.rad(angleZ)) * nplot.x + math.cos(math.rad(angleZ)) * nplot.y),
				z = round(nplot.z)
			};
			
			table.insert(plots, zplot);
		end
		local sorted = sortVector(plots);
		return sorted;
	end
	
	builder.sphere = function(radius, startV, endV, startH, endH)
		local plots = {};
		local step = 45 / radius;
		if (startV == nil) then startV = 0; end
		if (endV == nil) then endV = 360; end
		if (startH == nil) then startH = 0; end
		if (endH == nil) then endH = 360; end
		
		for x = startV, endV do
			local xplot = plot(x, radius);
			for z = startH, endH do
				local zplot = plot(z, xplot.h);
				table.insert(plots, {
					x = round(zplot.h),
					y = round(zplot.v),
					z = round(xplot.v)
				});
			end
		end
		local sorted = sortVector(plots);
		return sorted;
	end
end