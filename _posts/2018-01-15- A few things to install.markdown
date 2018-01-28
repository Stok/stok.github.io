---
layout: post
title:  "Installing python 3 OSX High Sierra"
date:   2018-01-15 13:00:00 +0100
categories: Projects
---

So, I want to be able to use python on a newly acquired macbook. High Sierra comes with Python 2.7, but not 3.+. So there's some installing to be done.

1. Install [brew]. There's a curl command which you just need to copy paste into the terminal.
2. Install python3 using brew 
```
brew install python3
```

3. Now for configuring the shell. Add a ~/.profile file (basically the same as a ~/.bash_profile) and include the following:
```
export LC_ALL="fr_FR.UTF-8"  
export LANG="fr_FR.UTF-8"
export PATH=/usr/local/bin:/usr/local/sbin:$PATH
alias pip=pip3
alias python=python3
```

The first two are language localisation settings. Adjust as needed. The third line adds `/usr/local/bin` and `/usr/local/sbin` to your PATH (to make sure the terminal can find programs you've installed). The last two are shortcuts: when I type `pip`/`python` in the terminal, it actually runs `pip3`/`python3`
. I basically never want to use python 2.7, and want to make sure I never accidentally call them.
Note: whenever you make changes to this file, you need to run `source ~/.profile` so the changes take effect.

Then, following [the hitchhiker's guide to python's page on virtual environments], I'll install `pipenv`. It's basically `pip` and `virtualenv` rolled into one. (the environements get installed to `~/.local/share/virtualenvs/`, with a shortcut at `~/`). To install, run:
```
pip install pipenv
```

The strategy is to install as little as possible globally (i.e. callable from anywhere), and keep as much as possible as project specific installations within a virtual environment.

The only other thing I install globally is [pip-autoremove]. It cleverly uninstalls dependencies that aren't used by anything else. It's quite useful when you accidentally do a global pip install...

[brew]: https://brew.sh
[the hitchhiker's guide to python's page on virtual environments]: http://docs.python-guide.org/en/latest/dev/virtualenvs/
[pip-autoremove]: https://github.com/invl/pip-autoremove


