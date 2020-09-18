MIDI EVENTS
Following the midi event delta-time comes the event type. The event type byte have a msb set to 1 (the value is >= 128). 

If it is a Meta Event, the command is FF.


The command byte is one byte, but is divided into 2 parts. The left 4 bits contain the actual command. The right 4 bits contain the midi channel number.

1ccc nnnn 

The data that follows a command byte have a msb of 0 (is less than 128).

There are 3 types of events: MIDI, SysEx and Meta.
