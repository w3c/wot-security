#dest = releases/note3
prev = /home/ashimura/public_html/www.w3.org/WWW/TR/2018/NOTE-wot-security-20181203
prev_overview = ../note2/Overview.html

document = https://w3c.github.io/wot-security/releases/note3/manifest.txt
decision = https://www.w3.org/2018/09/12-wot-minutes.html
token = 19196536455c055ab78fecc5.51525133

tidy:
	tidy -i -m Overview.html

diff:
	htmldiff.sh $(prev)/Overview.html Overview.html > diff.html

get-resources:
	./cp.sh

#install:
#	cp Overview.html diff.html tablestyle.css $(dest)
#	cp ${figs} ${dest}/images

publish:
	curl 'https://labs.w3.org/echidna/api/request' --data 'url=$(document)&decision=$(decision)&token=$(token)'
#	curl 'https://labs.w3.org/echidna/api/request' --data 'url=$(document)&decision=$(decision)&token=$(token)' -d 'dry-run=true'	

