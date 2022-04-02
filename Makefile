paper.html: paper.md
	pandoc -i paper.md -o paper.html --toc --standalone
