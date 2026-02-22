import time

from django.db import connection
from rest_framework.decorators import api_view
from rest_framework.response import Response

START_TIME = time.time()


def database_ok() -> bool:
    try:
        with connection.cursor() as cursor:
            cursor.execute('SELECT 1')
            cursor.fetchone()
        return True
    except Exception:
        return False


@api_view(['GET'])
def health(request):
    ok = database_ok()

    uptime_seconds = int(time.time() - START_TIME)

    return Response(
        {
            'status': 'ok' if ok else 'error',
            'uptime': uptime_seconds,
        },
        status=200 if ok else 503,
    )
