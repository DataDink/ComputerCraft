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
	
	local measure = function(x, y, z)
		if (x == nil) then x = 0; end
		if (y == nil) then y = 0; end
		if (z == nil) then z = 0; end
		return math.sqrt(x*x + y*y + z*z);
	end
	
	local extractNearestVector = function(vectors, vector)
		if (vectors == nill or vector == nil or vectors[1] == nil) then return nil; end
		local index = 0;
		local distance = nil;
		
		for i, compare in ipairs(vectors) do
			local dist = measure(compare.x - vector.x, compare.y - vector.y, compare.z - vector.z);
			if (distance == nil or dist < distance) then
				distance = dist;
				index = i;
			end
		end
		
		return table.remove(vectors, index);
	end
	
	local groupBy = function(objects, indexer)
		local results = {};
		local indexed = {};
		
		for i, object in ipairs(objects) do
			local key = indexer(object);
			if (indexed[key] == nil) then indexed[key] = {}; end
			table.insert(indexed[key], object);
		end
		
		local indexes = {};
		for key in pairs(indexed) do
			table.insert(indexes, key);
		end
		table.sort(indexes);
		
		for i, key in ipairs(indexes) do
			table.insert(results, indexed[key]);
		end
		return results;
	end
	
	local sortVectors = function(vectors)
		local results = {};
		local layers = groupBy(vectors, function(v) return v.z; end);
		for il, layer in ipairs(layers) do
			local plots = {};
			local rows = groupBy(layer, function(v) return v.y; end);
			for ir, row in ipairs(rows) do
				local columns = groupBy(row, function(v) return v.x; end);
				for ic, column in ipairs(columns) do
					table.insert(plots, column[1]);
				end
			end
			
			if (plots[1] ~= nil) then
				local plot = table.remove(plots, 1);
				table.insert(results, plot);
				
				while (plots[1] ~= nil) do
					plot = extractNearestVector(plots, plot);
					table.insert(results, plot);
				end
			end
		end
		return results;
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
				table.insert(plots, {
					x = round(zplot.h),
					y = round(zplot.v),
					z = round(xplot.v)
				});
			end
		end
		
		local sorted = sortVectors(plots);
		return sorted;
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
end

