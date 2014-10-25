MANSRCPATH := doc
MANPATH := man
MAN1SRC := $(wildcard $(MANSRCPATH)/*.1.md )
MAN5SRC := $(wildcard $(MANSRCPATH)/*.5.md )
MAN7SRC := $(wildcard $(MANSRCPATH)/*.7.md )
MAN1 := $(patsubst $(MANSRCPATH)/%,$(MANPATH)/man1/%,$(MAN1SRC:.md=))
MAN5 := $(patsubst $(MANSRCPATH)/%,$(MANPATH)/man5/%,$(MAN5SRC:.md=))
MAN7 := $(patsubst $(MANSRCPATH)/%,$(MANPATH)/man7/%,$(MAN7SRC:.md=))

.PHONY: clean tests changelog local-install

all: man

clean:
	@find -name '*~' -delete

man: $(MAN1) $(MAN5) $(MAN7)

$(MAN1) : $(MANPATH)/man1/%.1 : $(MANSRCPATH)/%.1.md
	m4 -P build-aux/tpl.m4 $< | build-aux/md2man -v title="$<" > $@

$(MAN5) : $(MANPATH)/man5/%.5 : $(MANSRCPATH)/%.5.md
	m4 -P build-aux/tpl.m4 $< | build-aux/md2man -v title="$<" > $@

$(MAN7) : $(MANPATH)/man7/%.7 : $(MANSRCPATH)/%.7.md
	m4 -P build-aux/tpl.m4 $< | build-aux/md2man -v title="$<" > $@

tests:
	@LC_ALL=C PATH="./bin:${PATH}" build-aux/shtest -E 'DIRCONFIG="tests/server/conf"' tests/server/*.t
#	@LC_ALL=C PATH="./bin:${PATH}" build-aux/shtest -E 'DIRCONFIG="tests/local/conf"' tests/local/*.t

changelog:
	@build-aux/gitlog-to-changelog --format="%h %s" | tr -s '\n' > ChangeLog

# upgrade configs, clear completion cache, upgrade completion code
multiuser:
	@rm -rf ~/.config/tmww
	@mkdir -p ~/.config/tmww
	@cp -RP conf/* ~/.config/tmww
	@mkdir -p ~/.tmp/lock
	@rm -rf ~/.oh-my-zsh/cache/TMWW*
	@mkdir -p ~/.oh-my-zsh/custom/plugins/tmww
	@cp ./zsh/tmww.plugin.zsh ~/.oh-my-zsh/custom/plugins/tmww

