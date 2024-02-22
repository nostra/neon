# Neon

Serve slides locally:
```shell
jupyter nbconvert --to slides *.ipynb --post serve
```


Open the rendered Jupyter slideshow on github:
https://nostra.github.io/neon/index.html

To open jupyter outside of Intellij:

```shell
source ./venv/bin/activate
jupyter server
```

Then open: http://localhost:8888/lab

## For ease of working with slides

Render into build directory upon change:
```shell
fswatch -0 *.ipynb | xargs -0 -I {} make
```

