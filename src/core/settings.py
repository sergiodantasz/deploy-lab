from pathlib import Path

from environ import FileAwareEnv

BASE_DIR = Path(__file__).resolve().parent.parent

env = FileAwareEnv()
env.read_env(BASE_DIR.parent / '.env', True)

SECRET_KEY = env.str('SECRET_KEY')

DEBUG = env.bool('DEBUG')

ALLOWED_HOSTS = env.list('ALLOWED_HOSTS')

INSTALLED_APPS = [
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'rest_framework',
    'tasks',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.middleware.common.CommonMiddleware',
]

ROOT_URLCONF = 'core.urls'

WSGI_APPLICATION = 'core.wsgi.application'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': env.str('POSTGRES_DB'),
        'USER': env.str('POSTGRES_USER'),
        'PASSWORD': env.str('POSTGRES_PASSWORD'),
        'HOST': env.str('POSTGRES_HOST', default='localhost'),
        'PORT': env.str('POSTGRES_PORT', default='5432'),
    }
}

LANGUAGE_CODE = 'en-us'

TIME_ZONE = 'UTC'

USE_I18N = True

USE_TZ = True

REST_FRAMEWORK = {
    'DEFAULT_RENDERER_CLASSES': ['rest_framework.renderers.JSONRenderer'],
}
