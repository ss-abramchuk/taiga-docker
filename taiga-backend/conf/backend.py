import os
from ast import literal_eval

from .common import *

DATABASES = {
   'default': {
       'ENGINE': 'django.db.backends.postgresql',
       'NAME': os.getenv('TAIGA_POSTGRES_DB'),
       'USER': os.getenv('TAIGA_POSTGRES_USER'),
       'PASSWORD': os.getenv('TAIGA_POSTGRES_PASSWORD'),
       'HOST': 'pgsql-server',
       'PORT': '5432',
   }
}

TAIGA_SCHEME = 'https' if os.getenv('TAIGA_SSL_ENABLE', default='False') == 'True' else 'http'
TAIGA_DOMAIN = os.getenv('TAIGA_DOMAIN', default='localhost')

MEDIA_ROOT = '/home/app/taiga/media'
MEDIA_URL = '{0}://{1}/media/'.format(TAIGA_SCHEME, TAIGA_DOMAIN)

STATIC_ROOT = '/home/app/taiga/static'
STATIC_URL = '{0}://{1}/static/'.format(TAIGA_SCHEME, TAIGA_DOMAIN)

ADMIN_MEDIA_PREFIX = '{0}://{1}/static/admin/'.format(TAIGA_SCHEME, TAIGA_DOMAIN)

SITES["front"]["scheme"] = TAIGA_SCHEME
SITES["front"]["domain"] = TAIGA_DOMAIN
SITES["api"]["scheme"] = TAIGA_SCHEME
SITES["api"]["domain"] = TAIGA_DOMAIN

SECRET_KEY = os.getenv('TAIGA_SECRET_KEY', default='insecurekey')

EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_USE_TLS = True if os.getenv('TAIGA_EMAIL_USE_TLS', default='False') == 'True' else False
EMAIL_USE_SSL = True if os.getenv('TAIGA_EMAIL_USE_SSL', default='False') == 'True' else False
EMAIL_HOST = os.getenv('TAIGA_EMAIL_HOST', default='localhost')
EMAIL_PORT = int(os.getenv('TAIGA_EMAIL_PORT', default='25'))
EMAIL_HOST_USER = os.getenv('TAIGA_EMAIL_HOST_USER', default='')
EMAIL_HOST_PASSWORD = os.getenv('TAIGA_EMAIL_HOST_PASSWORD', default='')
DEFAULT_FROM_EMAIL = os.getenv('TAIGA_DEFAULT_FROM_EMAIL', default='webmaster@localhost')
SERVER_EMAIL = os.getenv('TAIGA_DEFAULT_FROM_EMAIL', default='root@localhost')

TAIGA_DEBUG = True if os.getenv('TAIGA_DEBUG', default='False') == 'True' else False

DEBUG = TAIGA_DEBUG
TEMPLATE_DEBUG = TAIGA_DEBUG
PUBLIC_REGISTER_ENABLED = True if os.getenv('TAIGA_PUBLIC_REGISTER_ENABLED', default='False') == 'True' else False

TAIGA_EVENTS_ENABLE = True if os.getenv('TAIGA_EVENTS_ENABLE', default='False') == 'True' else False
if TAIGA_EVENTS_ENABLE is True:
    EVENTS_PUSH_BACKEND = "taiga.events.backends.rabbitmq.EventsPushBackend"
    EVENTS_PUSH_BACKEND_OPTIONS = {"url": "amqp://{0}:{1}@rabbitmq-server:5672/{2}".format(
        os.getenv('TAIGA_RABBITMQ_USER'), os.getenv('TAIGA_RABBITMQ_PASSWORD'), os.getenv('TAIGA_RABBITMQ_VHOST')
    )}

TAIGA_BACKUP_STORAGE = os.getenv('TAIGA_BACKUP_STORAGE')
if TAIGA_BACKUP_STORAGE is not None:
    DBBACKUP_STORAGE = TAIGA_BACKUP_STORAGE
    DBBACKUP_STORAGE_OPTIONS = literal_eval(os.getenv('TAIGA_BACKUP_OPTIONS'))

    TAIGA_BACKUP_KEEP = int(os.getenv('TAIGA_BACKUP_KEEP', default='10'))

    DBBACKUP_CLEANUP_KEEP = TAIGA_BACKUP_KEEP
    DBBACKUP_CLEANUP_KEEP_MEDIA = TAIGA_BACKUP_KEEP

    DBBACKUP_CONNECTORS = {
        'default': {
            'USER': os.getenv('POSTGRES_DEFAULT_USER'),
            'PASSWORD': os.getenv('POSTGRES_DEFAULT_PASS'),
            'HOST': 'pgsql-server',
            'CONNECTOR': 'dbbackup.db.postgresql.PgDumpBinaryConnector',
            'DROP': True,
            'RESTORE_SUFFIX': '--if-exists'
        }
    }

    INSTALLED_APPS += ["dbbackup"]
