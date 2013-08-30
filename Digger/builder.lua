if (builder == nil) then
	builder = {};
	
	local count = function(t)
		local c = 0;
		for i, v in pairs(t) do c = c + 1; end
		return c;
	end
	
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
	
	local insertVector = function(collection, vector)
		for i, v in pairs(collection) do
			if (v.x == vector.x and v.y == vector.y and v.z == vector.z) then return; end
		end
		table.insert(collection, vector);
	end
	
	local extractClosestVector = function(from, vectors)
		local result = nil;
		for i, v in pairs(vectors) do
			print(i .. " " .. v);
			local dist = measure(v.x - from.x, v.y - from.y, v.z - from.z);
			if (dist == 0) then
				table.remove(vectors, i);
			elseif (result == nil or dist < result.distance) then
				result = {
					index = i,
					vector = v,
					distance = dist
				};
			end
		end
		if (result == nil) then return nil; end
		return table.remove(vectors, result.index);
	end
	
	local sortBy = function(objects, indexer)
		local results = {};
		local indexed = {};
		local indexes = {};
		
		for i, v in pairs(objects) do
			local key = indexer(v);
			if (indexed[key] == nil) then indexed[key] = {}; end
			table.insert(indexed[key], v);
			table.insert(indexes, key);
		end
		
		table.sort(indexes);
		for i, key in pairs(indexes) do
			for i2, v in pairs(indexed[key]) do
				table.insert(results, v);
			end
		end
		return results;
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
	
	local sortVectors = function(vectors)
		local result = {};
		local refPoint = {};
		local lastPlot = {x = 0, y = 0, z = 0};
		local layers = groupBy(vectors, function(v) return v.z; end);
		
		for i, layer in pairs(layers) do
			layer = sortBy(layer, function(v) return v.y; end);
			while (lastPlot ~= nil) do
				lastPlot = extractClosestVector(lastPlot, layer);
				if (lastPlot ~= nil) then table.insert(result, lastPlot); end
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
		local sorted = sortVectors(plots);
		return sorted;
	end
	
	builder.sphere = function(radius, startV, endV, startH, endH)
		local plots = {};
		local step = 45 / radius;
		if (startV == nil) then startV = 0; end
		if (endV == nil) then endV = 360; end
		if (startH == nil) then startH = 0; end
		if (endH == nil) then endH = 360; end
		
		for x = startV, endV, step do
			local xplot = plot(x, radius);
			for z = startH, endH, step do
				local zplot = plot(z, xplot.h);
				insertVector(plots, {
					x = round(zplot.h),
					y = round(zplot.v),
					z = round(xplot.v)
				});
			end
		end
		
		local sorted = sortVectors(plots);
		return sorted;
	end

end

