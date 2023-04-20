
SRC   := $(wildcard draft-*.md)
TXT   := $(patsubst %.md,%.txt,$(SRC))
HTML  := $(patsubst %.md,%.html,$(SRC))
CWD   := $(shell pwd)
MMARK := $(CWD)/mmark/mmark

# Ensure the xml2rfc cache directory exists locally
IGNORE := $(shell mkdir -p $(HOME)/.cache/xml2rfc)

.PHONY: all clean jmap venv
.PRECIOUS: %.xml

all: $(TXT) $(HTML)

%.txt: %.xml venv/bin/xml2rfc
	source venv/bin/activate && xml2rfc --text -o $@ $<

%.html: %.xml venv/bin/xml2rfc
	source venv/bin/activate && xml2rfc --html -o $@ $<

%.xml: %.md $(MMARK)
	$(MMARK) $< > $@
	-tidy -indent -xml -quiet -wrap 80 < $@ > $@.tmp && mv $@.tmp $@ || rm $@.tmp

$(MMARK):
	cd mmark && go build

clean:
	-rm -f draft-*.txt draft-*.html draft-*.xml

xml2rfc: venv/bin/xml2rfc

venv/bin/xml2rfc: venv/bin/activate
	source venv/bin/activate && pip install xml2rfc

venv/bin/msgpack_decode: venv/bin/activate
	source venv/bin/activate && cd msgpack-python-pure && python setup.py develop

jmap: reaction.jmap reaction.jmap.msgpack vibrate.jmap vibrate.jmap.msgpack

%.jmap: %.eml venv eml-to-jmap.py
	source venv/bin/activate && ./eml-to-jmap.py $< > $@

%.jmap.msgpack: %.eml venv eml-to-jmap.py venv/bin/msgpack_decode
	source venv/bin/activate && ./eml-to-jmap.py -m $< > $@
ifeq ($(V), 1)
	source venv/bin/activate && msgpack_decode $@
endif

venv: venv/bin/activate

venv/bin/activate:
	virtualenv venv && source venv/bin/activate \
	    && cd jmapd && python setup.py develop
