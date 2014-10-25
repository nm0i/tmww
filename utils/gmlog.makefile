# gnu make specific
#
# defaults
LOGPATH:=${HOME}/log/gm/server.themanaworld.org

LOGS:=$(shell find "$(LOGPATH)" -name "gm*" -type f -printf '%f\n' )
MESSAGES := $(LOGS:gm.log.%=messages/messages.%)
BANS := $(LOGS:gm.log.%=records/bans.%)
BLOCKS := $(LOGS:gm.log.%=records/blocks.%)
FILED := $(LOGS:gm.log.%=dbupdate/filed.%)

LOGS:=$(addprefix $(LOGPATH)/,$(LOGS))
MESSAGES:=$(addprefix $(LOGPATH)/,$(MESSAGES))
BANS:=$(addprefix $(LOGPATH)/,$(BANS))
BLOCKS:=$(addprefix $(LOGPATH)/,$(BLOCKS))
FILED:=$(addprefix $(LOGPATH)/,$(FILED))

all: messages records

records: bans blocks allbanned allblocked

messages: $(MESSAGES)

messagesdir:
	mkdir -p $(LOGPATH)/messages
	chmod 770 $(LOGPATH)/messages

$(MESSAGES) : $(LOGPATH)/messages/messages.% : $(LOGPATH)/gm.log.% | messagesdir
	egrep -A 2 -B 2 '@l ' "$<" > "$@"

recordsdir:
	mkdir -p $(LOGPATH)/records
	chmod 770 $(LOGPATH)/records

bans: $(BANS)

allbanned: $(LOGPATH)/records/allbanned

$(LOGPATH)/records/allbanned: $(BANS)
	sed -n 's/^.* : @ban  *[^ ]* *//p' $(LOGPATH)/records/bans.* | \
		sort -u > $(LOGPATH)/records/allbanned

$(BANS) : $(LOGPATH)/records/bans.% : $(LOGPATH)/gm.log.% | recordsdir
	-grep -v '+5mn' "$<" | egrep '^.* : @ban' > "$@"

blocks: $(BLOCKS)

allblocked: $(LOGPATH)/records/allblocked

$(LOGPATH)/records/allblocked: $(BLOCKS)
	sed -n 's/^.* : @block  *//p' $(LOGPATH)/records/blocks.* | \
		sort -u > $(LOGPATH)/records/allblocked

$(BLOCKS) : $(LOGPATH)/records/blocks.% : $(LOGPATH)/gm.log.% | recordsdir
	-egrep '^.* : @block' "$<" > "$@"

dbupdate: $(FILED)

fileddir:
	@mkdir -p $(LOGPATH)/dbupdate
	@chmod 770 $(LOGPATH)/dbupdate

$(FILED) : $(LOGPATH)/dbupdate/filed.% : $(LOGPATH)/records/bans.% | fileddir
	@grep -v '+5mn' "$<" "$(subst $(LOGPATH)/records/bans,$(LOGPATH)/records/blocks,$<)" | \
	    sed -n 's/^.* : @block  *//p;s/^.* : @ban  *[^ ]* *//p'
	@touch "$@"

