from pytest import mark
from rest_framework.test import APIClient


@mark.django_db
def test_health_returns_ok(client: APIClient):
    response = client.get('/health/')
    assert response.status_code == 200
    assert response.json()['status'] == 'ok'
