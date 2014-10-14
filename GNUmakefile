MANSRCPATH := doc
MANPATH := man
MANSRC := $(wildcard $(MANSRCPATH)/*.[0-9].md )
MAN := $(patsubst $(MANSRCPATH)%,$(MANPATH)%,$(MANSRC:.md=))

.PHONY: clean tests changelog

all: man

clean:
	@find -name '*~' -delete

man: $(MAN)

$(MAN) : $(MANPATH)/% : $(MANSRCPATH)/%.md
	m4 -P build-aux/tpl.m4 $< | build-aux/md2man -v title="$<" > $@

tests:
	@LC_ALL=C PATH="./bin:${PATH}" build-aux/shtest -E 'DIRCONFIG="tests/server/conf"' tests/server/*.t
#	@LC_ALL=C PATH="./bin:${PATH}" build-aux/shtest -E 'DIRCONFIG="tests/local/conf"' tests/local/*.t

changelog:
	@build-aux/gitlog-to-changelog --format="%h %s" | tr -s '\n' > ChangeLog

