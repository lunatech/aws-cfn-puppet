CPP := cpp
JSONLINT := cat

.PHONY: all clean

all: aws-cfn-puppet.json

clean:
	rm -f *.json *.i *~

%.i : %.template
	$(CPP) $(CPPFLAGS) $< > $@

%.json : %.i
	egrep -v '^#' $< | $(JSONLINT) $(JSONLINTFLAGS) > $@
