local PlotService: {
	Collections: { [Player]: Model },
	PlotLookup: { [Model]: Player },
} = {}
PlotService.Collections = {}
PlotService.PlotLookup = {}

function PlotService.GetPlot(player: Player)
	local plot = PlotService.Collections[player]
	if not plot then
		plot = PlotService.Assign(player)
	end
	return plot
end

function PlotService.Assign(player: Player): Model
	local plots = (workspace.Plots :: Folder):GetChildren()
	for i, plot: Model in plots do
		if PlotService.PlotLookup[plot] then
			continue
		end
		PlotService.Collections[player] = plot
		PlotService.PlotLookup[plot] = player
		return plot
	end
	warn("ERROR NO PLOTS LEFT")
	return nil
end

function PlotService.ReturnPlot(player: Player)
	if not player then
		return
	end
	local plot = PlotService.Collections[player]
	PlotService.Collections[player] = nil
	if not plot then
		return
	end
	PlotService.PlotLookup[plot] = nil
end

return PlotService
