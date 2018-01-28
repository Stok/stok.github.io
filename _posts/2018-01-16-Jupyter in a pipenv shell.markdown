---
layout: post
title:  "Pipenv and its shell"
date:   2018-01-16 13:00:00 +0100
categories: Projects
---

A few quick examples of how to use pipenv.
So far, I've found that whenever anyone says `pip install package`, you can just replace `pip` with `pipenv`.
So, to install the notebook application [jupyter], run
```
pipenv install jupyter
```
Now, because you've installed it inside a virtual environment, you'll get a `command not found` error if you just type `jupyter notebook` in your terminal.
To access it, you need to open a shell that knows about the virtual environment. 
So run
```
pipenv shell".
```
Your terminal's input should go from looking like:
```
computer_name:folder_name user$ 
```
to something more like:
```
(folder_name_SOME_WEIRD_ID) bash-3.2$
```
Now you can run `jupyter notebook` and jupyter should run.

[jupyter]: http://jupyter.org

