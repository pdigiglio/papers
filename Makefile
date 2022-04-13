.PHONY: clean

paper.html: paper.bs
	bikeshed spec paper.bs paper.html

clean:
	rm -rvf paper.html
