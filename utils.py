import os


def get_env(key, required=False, default=None):
    try:
        return os.environ[key]
    except KeyError:
        if required:
            raise KeyError(f"Missing required environment variable {key}")
        return default


def get_env_bool(key, required=False, default='false') -> bool:
    value = get_env(key, required=required, default=default).lower()
    return value == 'true' or value == '1'


def get_env_int(key, required=False, default=None) -> int:
    value = get_env(key, required=required, default=default)
    return int(value)
