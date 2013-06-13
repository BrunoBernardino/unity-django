# Django settings for unity project.

DEBUG = False
TEMPLATE_DEBUG = DEBUG

ADMINS = (
	('Your Company Name', 'unity@yourdomain.com'),
)

MANAGERS = ADMINS

DATABASES = {
	'default': {
		'ENGINE': 'django.db.backends.mysql', # Add 'postgresql_psycopg2', 'mysql', 'sqlite3' or 'oracle'.
		'NAME': 'table_name',					  # Or path to database file if using sqlite3.
		'USER': 'table_user',					  # Not used with sqlite3.
		'PASSWORD': 'table_password',				  # Not used with sqlite3.
		'HOST': '',					  # Set to empty string for localhost. Not used with sqlite3.
		'PORT': '',					  # Set to empty string for default. Not used with sqlite3.
	}
}

TIME_ZONE = 'Europe/Lisbon'

LANGUAGE_CODE = 'en-gb'

SITE_ID = 1

USE_I18N = True

USE_L10N = True

USE_TZ = True

MEDIA_ROOT = '/some-http-accessible-path/media/'

MEDIA_URL = '/media/'

STATIC_ROOT = '/some-http-accessible-path/static/'

STATIC_URL = '/static/'

STATICFILES_DIRS = (
	'/project-path/static/',
)

STATICFILES_FINDERS = (
	'django.contrib.staticfiles.finders.FileSystemFinder',
	'django.contrib.staticfiles.finders.AppDirectoriesFinder',
#	'django.contrib.staticfiles.finders.DefaultStorageFinder',
	'compressor.finders.CompressorFinder'
)

SECRET_KEY = 'Some-Random-String'

TEMPLATE_LOADERS = (
	'django.template.loaders.filesystem.Loader',
	'django.template.loaders.app_directories.Loader',
#	 'django.template.loaders.eggs.Loader',
)

MIDDLEWARE_CLASSES = (
	'django.middleware.common.CommonMiddleware',
	'django.contrib.sessions.middleware.SessionMiddleware',
	'django.middleware.csrf.CsrfViewMiddleware',
	'django.contrib.auth.middleware.AuthenticationMiddleware',
	'django.contrib.messages.middleware.MessageMiddleware',
	# Uncomment the next line for simple clickjacking protection:
	# 'django.middleware.clickjacking.XFrameOptionsMiddleware',
)

ROOT_URLCONF = 'unity.urls'

WSGI_APPLICATION = 'unity.wsgi.application'

TEMPLATE_DIRS = (
	'/project-path/mytemplates',
)

INSTALLED_APPS = (
	'django.contrib.auth',
	'django.contrib.contenttypes',
	'django.contrib.sessions',
	'django.contrib.sites',
	'django.contrib.messages',
	'django.contrib.staticfiles',
	# Uncomment the next line to enable the admin:
	'django.contrib.admin',
	# Uncomment the next line to enable admin documentation:
	# 'django.contrib.admindocs',
	'compressor',
	'django_extensions',
	'imagekit',
	'mandrill',
	'projects',
)

AUTH_PROFILE_MODULE = 'projects.UserProfile'

COMPRESS_PRECOMPILERS = (
	('text/coffeescript', 'coffee --compile --stdio'),
	('text/less', 'lessc {infile} {outfile}'),
)

COMPRESS_JS_FILTERS = ['compressor.filters.jsmin.SlimItFilter']

LOGIN_URL = '/login/'
LOGIN_REDIRECT_URL = '/'

LOGGING = {
	'version': 1,
	'disable_existing_loggers': False,
	'filters': {
		'require_debug_false': {
			'()': 'django.utils.log.RequireDebugFalse'
		}
	},
	'handlers': {
		'mail_admins': {
			'level': 'ERROR',
			'filters': ['require_debug_false'],
			'class': 'django.utils.log.AdminEmailHandler'
		}
	},
	'loggers': {
		'django.request': {
			'handlers': ['mail_admins'],
			'level': 'ERROR',
			'propagate': True,
		},
	}
}

MAIN_URL = 'http://unity.yourdomain.com'

MANDRILL_API_KEY = 'your-api-key'

try:
	from local_settings import *
except ImportError:
	pass