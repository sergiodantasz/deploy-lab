from pytest import mark
from rest_framework.test import APIClient

from tasks.models import Task


@mark.django_db
def test_task_list_empty(client: APIClient):
    response = client.get('/api/tasks/')
    assert response.status_code == 200
    assert response.json() == []


@mark.django_db
def test_task_create(client: APIClient):
    response = client.post(
        '/api/tasks/',
        {'title': 'Test task'},
        format='json',
    )
    assert response.status_code == 201
    data = response.json()
    assert data['title'] == 'Test task'
    assert data['done'] is False
    assert 'id' in data


@mark.django_db
def test_task_retrieve(client: APIClient):
    task = Task.objects.create(title='My task', done=False)
    response = client.get(f'/api/tasks/{task.id}/')
    assert response.status_code == 200
    assert response.json()['title'] == 'My task'
