.PHONY: clean
.PHONY: build
.PHONY: run
.PHONY: copy
.PHONY: firstbuild

CMD=cat ~/.Playdate/config | sed -n 's/SDKRoot[[:space:]]\(.*\)/\1/p'
SDKREL=$(shell $(CMD))
SDKROOT=$(shell echo $(SDKREL))
SDKBIN=$(SDKROOT)/bin
GAME=$(notdir $(CURDIR))
SIM=Playdate Simulator


build: clean compile run

firstbuild: compile run

run: open

clean:
	rm -rf "$(GAME).pdx"

compile: Source/main.lua
	"$(SDKBIN)/pdc" 'Source' "$(GAME).pdx"
	
open:
	open -a "$(SDKBIN)/$(SIM).app/Contents/MacOS/$(SIM)" "$(GAME).pdx"
