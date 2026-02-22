from django.urls import include, path

from core.health import health

apipatterns = [
    path('tasks/', include('tasks.urls')),
]

urlpatterns = [
    path('health/', health),
    path('api/', include(apipatterns)),
]
