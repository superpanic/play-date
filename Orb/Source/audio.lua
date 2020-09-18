local lib_tim = playdate.timer

function new_audio_fx_player()
	local obj = {}
	
	local trot = 1.05946309436 -- twelfth root of two
	local first_a = 27.50
	obj.note_long_table = {first_a}
	for i = 2, 84 do
		obj.note_long_table[i] = obj.note_long_table[i-1] * trot
		--print(obj.note_long_table[i])
	end

	obj.note_table = {
		C_flat  = 261.63,
		C_sharp = 277.18,
		D_flat  = 293.66,
		D_sharp = 311.13,
		E_flat  = 329.63,
		F_flat  = 349.23,
		F_sharp = 369.99,
		G_flat  = 392.00,
		G_sharp = 415.30,
		A_flat  = 440.00,
		A_sharp = 466.16,
		B_flat  = 493.88
	}

	obj.note_array = {
		261.63,
		277.18,
		293.66,
		311.13,
		329.63,
		349.23,
		369.99,
		392.00,
		415.30,
		440.00,
		466.16,
		493.88
	}



	-- MODULATORS

	local lfo_sin12 = playdate.sound.lfo.new(playdate.sound.kLFOSine)
	lfo_sin12:setRate(12)

	local lfo_sin2 = playdate.sound.lfo.new(playdate.sound.kLFOSine)
	lfo_sin2:setRate(2)

	local lfo_sin20 = playdate.sound.lfo.new(playdate.sound.kLFOSine)
	lfo_sin20:setRate(20)


	-- EFFECTS

-- wall collide
	obj.sfx_collide = playdate.sound.synth.new(playdate.sound.kWaveTriangle)
	--                       A    D    S    R
	obj.sfx_collide:setADSR( 0.0, 0.5, 0.2, 0.1 )
	--obj.sfx_collide:setFrequencyMod(lfo_sin2)

	obj.play_collide = function()
		--playNote(pitch, volume, length)
		obj.sfx_collide:playNote(120, 0.5, 0.05)
	end
	obj.end_collide = function() obj.sfx_collide:noteOff() end



-- switch
	obj.sfx_switch = playdate.sound.synth.new(playdate.sound.kWaveSine)
	--
	obj.sfx_switch:setADSR( 0.0, 0.3, 0.2, 0.2 )
	obj.sfx_switch:setFrequencyMod(lfo_sin20)

	obj.play_switch = function()
		obj.sfx_switch:playNote(obj.note_table.B_flat, 0.5, 0.12)
	end
	obj.end_switch = function() obj.sfx_switch:noteOff() end



-- roll
	obj.sfx_roll = playdate.sound.synth.new(playdate.sound.kWaveSine)
	--                       A     D     S    R
	obj.sfx_roll:setADSR(   0.25, 0.25, 0.5, 0.5)
	obj.sfx_roll:setFrequencyMod(lfo_sin2)

	obj.play_roll = function()
		--playNote(pitch, volume, length)
		obj.sfx_roll:playNote(obj.note_table.D_flat, 0.5, 0.75)
	end
	obj.end_roll = function() obj.sfx_roll:noteOff() end



-- fall
	obj.sfx_fall = playdate.sound.synth.new(playdate.sound.kWaveSine)
	--                    A  D  S    R
	obj.sfx_fall:setADSR( 0, 0, 0.5, 0.2)
	--obj.sfx_fall:setFrequencyMod(lfo_sin2)

	obj.play_fall = function(p)
		p = math.floor( (p/8) + #obj.note_long_table / 2)
		if p < 1 then p = 1 end
		if p > #obj.note_long_table then p = #obj.note_long_table end
		obj.sfx_fall:playNote(obj.note_long_table[p], 1.0, 0.05)
	end
	obj.end_fall = function() obj.sfx_fall:noteOff() end



-- crash
	obj.sfx_crash = playdate.sound.synth.new(playdate.sound.kWaveNoise)
	--                    A  D  S    R
	obj.sfx_crash:setADSR( 0, 0, 0.2, 0.2)
	obj.sfx_crash:setFrequencyMod(lfo_sin12)

	obj.play_crash = function()
		--playNote(pitch, volume, length)
		obj.sfx_crash:playNote(75, 0.2, 0.2)
	end
	obj.end_crash = function() obj.sfx_crash:noteOff() end


	return obj
end

function print_all_notes(note_list)
	for i = 1, #note_list do
		print(
			" step "..note_list[i].step..
			" note "..note_list[i].note..
			" length "..note_list[i].length..
			" velocity "..note_list[i].velocity
		)
	end
end

function add_instrument_to_all_tracks_in_sequence(seq, inst)
	-- find used track in midi sequence
	local tcnt = seq:getTrackCount()
	local found_tracks = 0
	local longest_track = 0
	for i = 1, tcnt do
		local t = seq:getTrackAtIndex(i)
		local note_list = t:getNotes()
		if #note_list > 0 then
			print("in track: "..i.." notes: ".. #note_list)
			-- we found the track that contains data!
			t:setInstrument(inst)
			found_tracks = found_tracks+1
			local l = note_list[#note_list].step + note_list[#note_list].length
			if l > longest_track then 
				longest_track = l 
			end
		end
	end
	
	if not found_tracks then 
		print("cound not find any data in midi file") return 0
	end

	print("found total " .. found_tracks .. " music tracks")
	print("length: "..longest_track)
	print("length in milliseconds: "..(longest_track/seq:getTempo())*1000)

	-- return length in milliseconds
	return ( longest_track/seq:getTempo() ) * 1000
end

function load_midi_track(file_name, instrument)
	local midi = playdate.sound.sequence.new(file_name)
	local track_cnt = midi:getTrackCount()
	local track_copy = {}
	for i = 1, track_cnt do
		local midi_track = midi:getTrackAtIndex(i)
		local note_list = midi_track:getNotes()
		if #note_list > 0 then
			track_copy = playdate.sound.track.new()
			for n = 1, #note_list do
				track_copy:addNote(note_list[n])
			end
			track_copy:setInstrument(instrument)
		end
	end
	return track_copy
end

function song_player()
	local obj = {}

	obj.synth = playdate.sound.synth.new(playdate.sound.kWaveSawtooth)
	obj.synth:setADSR( 0.0, 0.5, 0.1, 0.1)

	obj.speed = 1000/8
	obj.step = 1
	obj.playing = false
	obj.is_looping = true

	obj.note_table = {
		C3 = 130.81,
		C3s = 138.59,
		D3 = 146.83,
		D3s = 155.56,
		E3 = 164.81,
		F3 = 174.61,
		F3s = 185.00,
		G3 = 196.00,
		G3s = 207.65,
		A3 = 220.00,
		A3s = 233.08,
		B3 = 246.94,
		C4 = 261.63,
		C4s = 261.63,
		D4 = 293.66,
		D4s = 311.13,
		E4 = 329.63,
		F4 = 349.23,
		F4s = 369.99,
		G4 = 392.00,
		G4s = 415.30,
		A4 = 440.00,
		A4s = 466.16,
		B4 = 493.88
	}

	obj.song = {
		{pitch="C3", velocity=0.61},
		{pitch="E3", velocity=0.57},
		{pitch="G3", velocity=0.56},
		{pitch="C4", velocity=0.60},
		{pitch="E4", velocity=0.63},
		{pitch="G3", velocity=0.50},
		{pitch="C4", velocity=0.47},
		{pitch="E4", velocity=0.47},

		{pitch="C3", velocity=0.62},
		{pitch="E3", velocity=0.57},
		{pitch="G3", velocity=0.56},
		{pitch="C4", velocity=0.60},
		{pitch="E4", velocity=0.62},
		{pitch="G3", velocity=0.50},
		{pitch="C4", velocity=0.48},
		{pitch="E4", velocity=0.48},

		{pitch="C3", velocity=0.65},
		{pitch="D3", velocity=0.60},
		{pitch="A3", velocity=0.56},
		{pitch="D4", velocity=0.60},
		{pitch="F4", velocity=0.65},
		{pitch="A3", velocity=0.51},
		{pitch="D4", velocity=0.50},
		{pitch="F4", velocity=0.50},

		{pitch="C3", velocity=0.65},
		{pitch="D3", velocity=0.60},
		{pitch="A3", velocity=0.58},
		{pitch="D4", velocity=0.60},
		{pitch="F4", velocity=0.65},
		{pitch="A3", velocity=0.52},
		{pitch="D4", velocity=0.50},
		{pitch="F4", velocity=0.50}
	}
	
	obj.play = function()
		obj.playing = true
		obj.play_next_note()
	end

	obj.play_next_note = function()
		if not obj.playing then 
			return 
		end

		local pitch = obj.song[obj.step].pitch
		local velocity = obj.song[obj.step].velocity

		if obj.step >= #obj.song then
			obj.step = 1
			if not obj.is_looping then 
				obj.stop() 
			end
		else
			obj.step = obj.step + 1
		end

		if pitch == "pause" then
			-- silence
		else
			obj.synth:playNote(obj.note_table[pitch], velocity, 1.0)
		end
		
		lib_tim.performAfterDelay(obj.speed, obj.play_next_note)
	end

	obj.stop = function()
		obj.playing = false
	end

	return obj
	
end
