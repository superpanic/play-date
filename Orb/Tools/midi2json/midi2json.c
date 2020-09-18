#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <stdbool.h>
#include <math.h>

#define DEBUG 1

#define MIN(X, Y) (((X) < (Y)) ? (X) : (Y))
#define MAX(X, Y) (((X) > (Y)) ? (X) : (Y))

/* We only use unsigned types */
typedef unsigned char t_1byte;
typedef unsigned short t_2byte;
typedef unsigned int t_4byte;
typedef unsigned long t_8byte;

void die(const char *message);
void print_type_lengths();
unsigned int reverse_endian_int(unsigned int x);
unsigned short reverse_endian_short(unsigned short x);
unsigned int ticks_per_second(unsigned int ticks_per_beat, unsigned int beats_per_minute);
unsigned char get_low_bits(unsigned char c);
unsigned char get_high_bits(unsigned char c);

const int META_EVENT_TYPE_ARR[15] = {
	0x00, 0x01, 0x02, 0x03, 0x04, 
	0x05, 0x06, 0x07, 0x20, 0x2F, 
	0x51, 0x54, 0x58, 0x59, 0x7F
};

const int META_EVENT_LENGTH_ARR[15] = {
	 2,-1,-1,-1,-1,
	-1,-1,-1, 1, 0,
	3, 5, 4, 2, -2
};
// -1 string, -2 variable length

const char META_EVENT_NAME_ARR[15][20] = {
	"Sequence Number",
	"Text Event",
	"Copyright Notice",
	"Sequence/Track Name",
	"Instrument Name",

	"Lyrics",
	"Marker",
	"Cue Point",
	"Midi Channel Prefix",
	"End of Track",

	"Set tempo",
	"SMPTE Offset",
	"Time Signature",
	"Key Signature",
	"Sequencer Specific"
};


int main(int argc, char *argv[]) {
	if (DEBUG) print_type_lengths();
	if (argc < 3) die("Please provide [FILENAME_IN] and [FILENAME_OUT].");
	
	char filename_in[64];
	strncpy(filename_in, argv[1], 64);
	filename_in[64-1] = '\0';

	char filename_out[64];
	strncpy(filename_out, argv[2], 64);
	filename_out[64-1] = '\0';

	FILE *file_ptr;
	printf("Opening file %s\n", filename_in);

	file_ptr = fopen(filename_in, "rb");
	if(file_ptr == NULL) die("File not found.");
	printf("File \"%s\" open for reading.\n", filename_in);
	
// read file header MThd

	const char *FILE_HEADER = "MThd";
	int read_len = 4;
	t_1byte file_header[read_len];
	fread(file_header, sizeof(file_header[0]), read_len, file_ptr);
	bool is_a_midi_file = true;
	for(int i=0; i<read_len; i++) {
		printf("%c", file_header[i]);
		if(FILE_HEADER[i] != file_header[i]) {
			is_a_midi_file = false;
		}
	}
	printf("\n");
	if (!is_a_midi_file) die("Not a midi-file.");
	printf("Midi file header signature ok.\n");

// read the file header size (big endian)

	printf("Header info:\n");

	t_4byte file_header_size;
	fread(&file_header_size, sizeof(t_4byte), 1, file_ptr);
	file_header_size = reverse_endian_int(file_header_size);
	printf("\tFile header size: %u\n", file_header_size);

	t_2byte file_format;
	fread(&file_format, sizeof(file_format), 1, file_ptr);
	file_format = reverse_endian_short(file_format);
	if(file_format == 0) {
		printf("\tFile format: %u (single track)\n", file_format);
	} else {
		die("Unsupported Midi-file format.");
	}

	t_2byte number_of_tracks;
	fread(&number_of_tracks, sizeof(number_of_tracks), 1, file_ptr);
	number_of_tracks = reverse_endian_short(number_of_tracks);
	printf("\tNumber of tracks: %u\n", number_of_tracks);

	t_2byte delta_time_ticks;
	fread(&delta_time_ticks, sizeof(delta_time_ticks), 1, file_ptr);
	delta_time_ticks = reverse_endian_short(delta_time_ticks);
	printf("\tDelta time ticks: %u\n", delta_time_ticks);

// read midi track

	printf("Track info:\n");

	const char *TRACK_HEADER = "MTrk";
	read_len = 4;
	t_1byte track_header[read_len + 1];
	fread(track_header, sizeof(track_header[0]), read_len, file_ptr);
	bool is_a_midi_track = true;
	for(int i=0; i<read_len; i++) {
		//printf("%c", track_header[i]);
		if(TRACK_HEADER[i] != track_header[i]) {
			is_a_midi_track = false;
		}
	}
	track_header[read_len] = '\0';

	if (!is_a_midi_track) die("Could not find midi-track.");
	printf("\tMidi track header signature: %s\n",track_header);

	t_4byte number_of_events;
	fread(&number_of_events, sizeof(number_of_events), 1, file_ptr);
	number_of_events = reverse_endian_int(number_of_events);
	printf("\tTrack length: %u\n", number_of_events);

// midi event delta time:

// event loop:
	const int delta_time_max_bytes = 4;
	for(int event = 0; event < number_of_events; event++) {
		
		// reading delta time	
		t_1byte delta_time_buffer[delta_time_max_bytes];
		t_1byte delta_time_byte=0xFF;
		int byte_counter = 0;
		while(delta_time_byte>=0x08) {
			fread(&delta_time_byte, sizeof(delta_time_byte), 1, file_ptr);
			delta_time_buffer[byte_counter] = delta_time_byte;
			byte_counter++;
		}
		
		// calculate delta time
		int delta_time_value = 0;
		for(int i = 0; i<byte_counter; i++) {
			int dt = delta_time_buffer[i] & 127; // set msb to 0
			delta_time_value = delta_time_value << 7; // leave room for 7 bits
			delta_time_value = delta_time_value + dt; // add new value
		}
		printf("Event %u at delta time: %u\n", event, delta_time_value);
		
		// read command type
		t_1byte command_byte;
		fread(&command_byte, sizeof(command_byte), 1, file_ptr);
		if(command_byte < 0x80) {
			printf("\tUnknown command value: %u\n", (unsigned char) command_byte);
			die("Expected midi command, got unknown value.");
		}

		// read meta event
		if(command_byte == 0xFF) {
			t_1byte meta_event_type;
			fread(&meta_event_type, sizeof(meta_event_type), 1, file_ptr);
			int err_val = 99;
			int meta_event_length = err_val;
			for(int i = 0; i<15; i++) {
				if(meta_event_type == META_EVENT_TYPE_ARR[i]) {
					printf("\tFound meta event: %s\n", META_EVENT_NAME_ARR[i]);
					printf("\tMeta event length: %d\n", META_EVENT_LENGTH_ARR[i]);
					meta_event_length = META_EVENT_LENGTH_ARR[i];
					break;
				}
			}
			if(meta_event_length == err_val) die("Unknown Midi Meta event type.");
			if(meta_event_length == -1) {
				// string
			} else if(meta_event_length == -2) {
				// variable length
			} else {
				t_1byte meta_event_value[meta_event_length];
				fread(meta_event_value, sizeof(meta_event_value[0]), meta_event_length, file_ptr);
				printf("\tMeta event data:\n");
				for(int i=0;i<meta_event_length;i++) {
					printf("\t %u ", (unsigned char) meta_event_value[i]);
				}
				printf("\n");
			}
		} else {
			printf("\tThis is a midi event.");
			printf("\tThe command: %u\n", (unsigned char) get_high_bits(command_byte) );
			printf("\tThe channel: %u\n", (unsigned char) get_low_bits(command_byte) );
		}

		if(event >= 2) die("!");

	}

	
// close file
	fclose(file_ptr);

	return 0;
}

unsigned char get_low_bits(unsigned char c) {
	return c & 0x0F;
}

unsigned char get_high_bits(unsigned char c) {
	return c >> 4;
}

unsigned short reverse_endian_short(unsigned short x) {
	return (
		( (x >> 8) & 0x00ff ) | 
		( (x << 8) & 0xff00 )
	);
}

unsigned int reverse_endian_int(unsigned int x) {
	return (
		( (x >> 24) & 0x000000ff ) | 
		( (x >>  8) & 0x0000ff00 ) | 
		( (x <<  8) & 0x00ff0000 ) | 
		( (x << 24) & 0xff000000 )
	);
}

void die(const char *message) {
	if (errno) {
		perror(message);
	} else {
		printf("ERROR: %s\n", message);
	}
	exit(errno);
}

void print_type_lengths() {
	/* print some byte lengths of types */
	printf("================\n");
	printf("  %lu bytes (unsigned char)  : t_1byte\n", sizeof(t_1byte));
	printf("  %lu bytes (unsigned short) : t_2byte\n", sizeof(t_2byte));
	printf("  %lu bytes (unsigned int)   : t_4byte\n", sizeof(t_4byte));
	printf("  %lu bytes (unsigned long)  : t_8byte\n", sizeof(t_8byte));
	printf("================\n");
}

unsigned int ticks_per_second(unsigned int ticks_per_beat, unsigned int beats_per_minute) {
	int ticks_per_minute = beats_per_minute * ticks_per_beat;
	int ticks_per_second = ticks_per_minute / 60;
	return ticks_per_second;
}