# Unity

Unity is a Project Manager built by me for Wozia, using Django.
It lacks a few features (like search and chat), but since it's not being used anymore, I've decided to post it up here as it might be helpful for someone else.

It uses Backbone.js, LESS, CoffeeScript and was built in mid-2012, with only minor incremental updates, so some things might be outdated already.

It uses Mandrill to send emails.

**NOTE:** I didn't remove all links and logos from Wozia (though they will not work), so be sure to do that yourself. You'll find all occurrences in mytemplates/* (and this README.md file).

## Installation

This will not go through having a Django project running using fastcgi or whatever, I assume you know how to do that. I just list here a few things you'll need to install (you might have some if you're already running some Django projects). I'm also using Debian as a base, but it shouldn't be too hard to find other Linux equivalents.

### Debian packages for Python

```bash
apt-get install python-mysqldb python-flup python-django python-imaging python-imaging-tk python-pip
```

**NOTE:** On Debian squeeze, squeeze-backports repository may be needed for more up-to-date versions. Then you can install using:
```bash
apt-get -t squeeze-backports install python-django
```

### Python packages

```bash
pip install django_compressor
pip install django-extensions
pip install django-imagekit
pip install pytz
```

### Other requirements

Install node.js ( http://nodejs.org/ ) for coffee-script and less.

## Local/Development settings
You are expected to have the production settings on unity/settings.py and you can override them creating a unity/local_settings.py file (already ignored by git)

## Deploy/Start

To synchronize the DB and generate the CSS/JS minified and concatenated files, run:

```bash
cd PATH_TO_PROJECT_DIR && python manage.py syncdb && python manage.py collectstatic --noinput
```

And off you go!