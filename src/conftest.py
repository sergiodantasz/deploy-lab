from pytest import fixture
from rest_framework.test import APIClient


@fixture
def client():
    return APIClient()
