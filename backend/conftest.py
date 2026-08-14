import pytest


@pytest.fixture(autouse=True)
def _tmp_media_root(settings, tmp_path):
    if settings.STORAGE_BACKEND == "local":
        settings.MEDIA_ROOT = tmp_path
