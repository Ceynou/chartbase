local ncdk = require("ncdk")
local NoteChart = require("ncdk.NoteChart")
local Osu = require("osu.Osu")
local NoteDataExporter = require("osu.NoteDataExporter")
local TimingDataExporter = require("osu.TimingDataExporter")
local mappings = require("osu.exportKeyMappings")

local NoteChartExporter = {}

local NoteChartExporter_metatable = {}
NoteChartExporter_metatable.__index = NoteChartExporter

NoteChartExporter.new = function(self)
	local noteChartExporter = {}
	
	noteChartExporter.metaData = {}
	
	setmetatable(noteChartExporter, NoteChartExporter_metatable)
	
	return noteChartExporter
end

NoteChartExporter.export = function(self)
	local inputMode = self.noteChart.inputMode
	self.mappings = mappings[inputMode:getString()]
	if not self.mappings then
		local keymode = inputMode:getInputCount("key")
		self.mappings = {
			keymode = keymode > 0 and keymode or 1
		}
	end
	
	self.events = {}
	self.hitObjects = {}
	self:loadNotes()
	
	self.lines = {}
	
	self:addHeader()
	self:addEvents()
	self:addTimingPoints()
	self:addHitObjects()
	
	return table.concat(self.lines, "\n")
end

NoteChartExporter.loadNotes = function(self)
	local events = self.events
	local hitObjects = self.hitObjects
	
	for layerIndex in self.noteChart:getLayerDataIndexIterator() do
		local layerData = self.noteChart:requireLayerData(layerIndex)
		for noteDataIndex = 1, layerData:getNoteDataCount() do
			local noteData = layerData:getNoteData(noteDataIndex)
			if noteData.noteType == "ShortNote" or noteData.noteType == "LongNoteStart" then
				local nde = NoteDataExporter:new()
				nde.mappings = self.mappings
				nde.noteData = noteData
				hitObjects[#hitObjects + 1] = nde:getHitObject()
			elseif noteData.noteType == "SoundNote" then
				local nde = NoteDataExporter:new()
				nde.noteData = noteData
				events[#events + 1] = nde:getEventSample()
			end
		end
	end
end

NoteChartExporter.addHeader = function(self)
	local lines = self.lines
	
	lines[#lines + 1] = "osu file format v14"
	lines[#lines + 1] = ""
	lines[#lines + 1] = "[General]"
	lines[#lines + 1] = "AudioFilename: virtual"
	lines[#lines + 1] = "AudioLeadIn: 0"
	lines[#lines + 1] = "PreviewTime: 0"
	lines[#lines + 1] = "Countdown: 0"
	lines[#lines + 1] = "SampleSet: Soft"
	lines[#lines + 1] = "StackLeniency: 0.7"
	lines[#lines + 1] = "Mode: 3"
	lines[#lines + 1] = "LetterboxInBreaks: 0"
	lines[#lines + 1] = ""
	lines[#lines + 1] = "[Metadata]"
	lines[#lines + 1] = "Title:"
	lines[#lines + 1] = "TitleUnicode:"
	lines[#lines + 1] = "Artist:"
	lines[#lines + 1] = "ArtistUnicode:"
	lines[#lines + 1] = "Creator:"
	lines[#lines + 1] = "Version:"
	lines[#lines + 1] = "Source:"
	lines[#lines + 1] = "Tags:"
	lines[#lines + 1] = "BeatmapID:0"
	lines[#lines + 1] = "BeatmapSetID:-1"
	lines[#lines + 1] = ""
	lines[#lines + 1] = "[Difficulty]"
	lines[#lines + 1] = "HPDrainRate:5"
	
	lines[#lines + 1] = "CircleSize:" .. self.mappings.keymode
	
	lines[#lines + 1] = "OverallDifficulty:5"
	lines[#lines + 1] = "ApproachRate:5"
	lines[#lines + 1] = "SliderMultiplier:1.4"
	lines[#lines + 1] = "SliderTickRate:1"
	lines[#lines + 1] = ""
end

NoteChartExporter.addEvents = function(self)
	local lines = self.lines
	local events = self.events
	
	lines[#lines + 1] = "[Events]"
	lines[#lines + 1] = "//Background and Video events"
	lines[#lines + 1] = "0,0,\"background.jpg\",0,0"
	lines[#lines + 1] = "//Break Periods"
	lines[#lines + 1] = "//Storyboard Layer 0 (Background)"
	lines[#lines + 1] = "//Storyboard Layer 1 (Fail)"
	lines[#lines + 1] = "//Storyboard Layer 2 (Pass)"
	lines[#lines + 1] = "//Storyboard Layer 3 (Foreground)"
	
	lines[#lines + 1] = "//Storyboard Sound Samples"
	for i = 1, #events do
		lines[#lines + 1] = events[i]
	end
	
	lines[#lines + 1] = ""
end

NoteChartExporter.addTimingPoints = function(self)
	local lines = self.lines
	
	lines[#lines + 1] = "[TimingPoints]"
	
	local layerData = self.noteChart:requireLayerData(1)
	for tempoDataIndex = 1, layerData:getTempoDataCount() do
		local tde = TimingDataExporter:new()
		tde.tempoData = layerData:getTempoData(tempoDataIndex)
		lines[#lines + 1] = tde:getTempo()
	end
	for stopDataIndex = 1, layerData:getStopDataCount() do
		local tde = TimingDataExporter:new()
		tde.stopData = layerData:getStopData(stopDataIndex)
		lines[#lines + 1] = tde:getStop()
	end
	
	lines[#lines + 1] = ""
end

NoteChartExporter.addHitObjects = function(self)
	local lines = self.lines
	local hitObjects = self.hitObjects
	
	lines[#lines + 1] = "[HitObjects]"
	for i = 1, #hitObjects do
		lines[#lines + 1] = hitObjects[i]
	end
end

return NoteChartExporter