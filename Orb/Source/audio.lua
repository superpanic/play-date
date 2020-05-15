function new_audio_fx_player()
	local obj = {}
	
	obj.trot = 1.05946309436 -- twelfth root of two
	
	obj.note_table = {
		C = 261.63,
		Cb= 277.18,
		D = 293.66,
		Db= 311.13,
		E = 329.63,
		Eb= 349.23,
		Fb= 369.99,
		G = 392.00,
		Gb= 415.30,
		A = 440.00,
		Ab= 466.16,
		B = 493.88
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
	-- fast sine lfo
	local lfo_sin12 = playdate.sound.lfo.new(playdate.sound.kLFOSine)
	lfo_sin12:setDepth(0.5)
	lfo_sin12:setCenter(0.5)
	--lfo_sin12:setDelay(0.1,0.1)
	lfo_sin12:setRate(12)

	-- slow sine lfo
	local lfo_sin2 = playdate.sound.lfo.new(playdate.sound.kLFOSine)
	lfo_sin2:setDepth(0.5)
	lfo_sin2:setCenter(0.5)
	--lfo_sin2:setDelay(0.1,0.1)
	lfo_sin2:setRate(2)



	-- EFFECTS

	-- collide
	obj.sfx_collide = playdate.sound.synth.new(playdate.sound.kWaveTriangle)
	--                       A    D    S    R
	obj.sfx_collide:setADSR( 0.0, 0.0, 0.2, 0.2)
	obj.sfx_collide:setFrequencyMod(lfo_sin12)

	obj.play_collide = function()
		--playNote(pitch, volume, length)
		obj.sfx_collide:playNote(obj.note_table.C, 0.5, 0.2)
	end
	obj.end_collide = function() obj.sfx_collide:noteOff() end


	-- roll
	obj.sfx_roll = playdate.sound.synth.new(playdate.sound.kWaveSine)
	--                       A     D     S    R
	obj.sfx_roll:setADSR(   0.25, 0.25, 0.5, 0.5)
	obj.sfx_roll:setFrequencyMod(lfo_sin2)

	obj.play_roll = function()
		--playNote(pitch, volume, length)
		obj.sfx_roll:playNote(obj.note_table.D, 0.5, 0.75)
	end
	obj.end_roll = function() obj.sfx_roll:noteOff() end


	-- crash
	obj.sfx_crash = playdate.sound.synth.new(playdate.sound.kWaveNoise)
	--                    A  D  S    R
	obj.sfx_crash:setADSR( 0, 0, 0.25, 0.1)
	obj.sfx_crash:setFrequencyMod(lfo_sin12)

	obj.play_crash = function(p)
		if not p then p = 65.41 end
		--playNote(pitch, volume, length)
		obj.sfx_crash:playNote(p, 0.5, 0.2)
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

function new_music_player()
	local obj = {}

	obj.is_looping = false

	-- create a synth
	obj.synth = playdate.sound.synth.new(playdate.sound.kWaveSine)
	obj.synth:setADSR(   0, 0, 0.5, 0.05) -- ADSR

	-- create an instument using the sine wave synth
	obj.instr_sine_synth = playdate.sound.instrument.new()
	obj.instr_sine_synth:addVoice(obj.synth)

	-- load title midi sequence
	obj.title_sequence = playdate.sound.sequence.new('Audio/title.mid')
	obj.title_sequence_length = add_instrument_to_all_tracks_in_sequence(obj.title_sequence, obj.instr_sine_synth)

	obj.play_title = function(loop)
		print("playing title music")
		obj.title_sequence:play()
		if loop then
			-- TODO: callback timer
			playdate.timer.performAfterDelay(4000, obj.loop_title)
			obj.is_looping = true
		end
	end

	obj.loop_title = function()
		if obj.is_looping then
			obj.title_sequence:play()
			playdate.timer.performAfterDelay(4000, obj.loop_title)
		end
	end

	obj.stop_title = function()
		--print("stop playing title song")
--		obj.title_sequence:setTempo(1)
--		obj.title_sequence:stop() -- FIXME: this stop() command causes hard crash on emulator and hardware
--		obj.title_sequence:goToStep(3721)
		obj.title_sequence:setTempo(0)

		obj.is_looping = false
	end

	return obj
end
