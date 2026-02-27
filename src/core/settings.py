from pathlib import Path

from environ import FileAwareEnv

BASE_DIR = Path(__file__).resolve().parent.parent

env = FileAwareEnv()
env.read_env(BASE_DIR.parent / '.env', True)

SECRET_KEY = env.str('SECRET_KEY')

DEBUG = env.bool('DEBUG')
CURRENT_ENV = env.str('CURRENT_ENV')

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
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
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

if CURRENT_ENV == 'production':
    DEBUG = False

    SECURE_SSL_REDIRECT = True
    SECURE_HSTS_SECONDS = 86400
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True

    SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
    USE_X_FORWARDED_HOST = True

    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True

    SECURE_BROWSER_XSS_FILTER = True
    SECURE_CONTENT_TYPE_NOSNIFF = True
