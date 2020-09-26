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
	obj.sfx_collide:setADSR( 0.0, 0.5, 0.2, 0.1 )
	--obj.sfx_collide:setFrequencyMod(lfo_sin2)

	obj.play_collide = function()
		--playNote(pitch, volume, length)
		obj.sfx_collide:playNote(120, 0.5, 0.05)
	end
	obj.end_collide = function() obj.sfx_collide:noteOff() end



	-- switch
	obj.sfx_switch = playdate.sound.synth.new(playdate.sound.kWaveSine)
	obj.sfx_switch:setADSR( 0.0, 0.3, 0.2, 0.2 )
	obj.sfx_switch:setFrequencyMod(lfo_sin20)

	obj.play_switch = function()
		obj.sfx_switch:playNote(obj.note_table.B_flat, 0.5, 0.12)
	end
	obj.end_switch = function() obj.sfx_switch:noteOff() end



	-- roll
	obj.sfx_roll = playdate.sound.synth.new(playdate.sound.kWaveSine)
	obj.sfx_roll:setADSR(   0.25, 0.25, 0.5, 0.5)
	obj.sfx_roll:setFrequencyMod(lfo_sin2)

	obj.play_roll = function()
		--playNote(pitch, volume, length)
		obj.sfx_roll:playNote(obj.note_table.D_flat, 0.5, 0.75)
	end
	obj.end_roll = function() obj.sfx_roll:noteOff() end



	-- fall
	obj.sfx_fall = playdate.sound.synth.new(playdate.sound.kWaveSine)
	obj.sfx_fall:setADSR( 0.0, 0.5, 0.1, 0.1)
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
	obj.sfx_crash:setADSR( 0, 0, 0.2, 0.2)
	obj.sfx_crash:setFrequencyMod(lfo_sin12)

	obj.play_crash = function()
		--playNote(pitch, volume, length)
		obj.sfx_crash:playNote(75, 0.2, 0.2)
	end
	obj.end_crash = function() obj.sfx_crash:noteOff() end


	return obj
end

function song_player()
	local obj = {}

	-- create a synth
	obj.synth = playdate.sound.synth.new(playdate.sound.kWaveSawtooth)
	obj.synth:setADSR( 0.0, 0.5, 0.1, 0.1)

	-- read midi data
	obj.midi_data = playdate.datastore.read("Json/midi")
	print(obj.midi_data.loadmessage) -- test, to make sure the json is readable
	obj.song = obj.midi_data.notes

	-- song state variables
	obj.playing = false
	obj.is_looping = obj.midi_data.loop
	obj.step = 1
	obj.delay_multiplier = obj.midi_data.delay

	obj.play = function()
		obj.playing = true
		obj.play_next_note()
	end

	obj.play_next_note = function(the_note)
		if not obj.playing then 
			return 
		end

		-- play incoming note (if any)
		if the_note then
			if the_note.c == "Note ON" then
				obj.synth:playNote(the_note.f, the_note.v/128, 1.0)
			end
		end

		-- prepare next note
		local delay = obj.song[obj.step].d * obj.delay_multiplier
		local next_note = obj.song[obj.step]
		lib_tim.performAfterDelay(delay, obj.play_next_note, next_note)

		-- step to next
		if obj.step >= #obj.song then
			obj.step = 1
			if not obj.is_looping then 
				obj.stop() 
			end
		else
			obj.step = obj.step + 1
		end

	end

	obj.stop = function()
		obj.playing = false
	end

	return obj
end
