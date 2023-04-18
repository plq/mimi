
SRC   := $(wildcard draft-*.md)
TXT   := $(patsubst %.md,%.txt,$(SRC))
CWD   := $(shell pwd)
MMARK := $(CWD)/mmark/mmark

# Ensure the xml2rfc cache directory exists locally
IGNORE := $(shell mkdir -p $(HOME)/.cache/xml2rfc)

all: $(TXT) $(HTML)

%.txt: %.xml
	xml2rfc --text -o $@ $<

%.html: %.xml
	xml2rfc --html -o $@ $<

%.xml: %.md $(MMARK)
	$(MMARK) $< > $@

$(MMARK):
	cd mmark && go build

clean:
	-rm -f draft-*.txt draft-*.html draft-*.xml

