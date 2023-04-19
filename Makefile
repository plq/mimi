
SRC   := $(wildcard draft-*.md)
TXT   := $(patsubst %.md,%.txt,$(SRC))
HTML  := $(patsubst %.md,%.html,$(SRC))
CWD   := $(shell pwd)
MMARK := $(CWD)/mmark/mmark

# Ensure the xml2rfc cache directory exists locally
IGNORE := $(shell mkdir -p $(HOME)/.cache/xml2rfc)

.PHONY: all clean jmap

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

jmap: reaction.jmap reaction.jmap.msgpack vibrate.jmap vibrate.jmap.msgpack

%.jmap: %.eml venv eml-to-jmap.py
	source venv/bin/activate && ./eml-to-jmap.py $< > $@

%.jmap.msgpack: %.eml venv eml-to-jmap.py
	source venv/bin/activate && ./eml-to-jmap.py -m $< > $@

venv:
	virtualenv venv && source venv/bin/activate \
	    && cd jmapd && python setup.py develop
