function new_audio_fx_player()
	local obj = {}
	
	obj.trot = 1.05946309436 -- twelfth root of two
	
	obj.note_table = {
		C = 261.63,
		Cs= 277.18,
		D = 293.66,
		Ds= 311.13,
		E = 329.63,
		Es= 349.23,
		Fs= 369.99,
		G = 392.00,
		Gs= 415.30,
		A = 440.00,
		As= 466.16,
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
