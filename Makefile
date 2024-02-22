MAIN = build

all: build

clean:
	rm -f pandora.slides.html
	rm -rf build

%.slides.html: %.ipynb
	jupyter nbconvert --to slides $< --config _config.yaml

build: pandora.slides.html
	mkdir -p build
	mv $< build/index.html
	# cp -r image build/.
