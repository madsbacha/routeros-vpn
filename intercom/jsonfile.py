import json
from typing import Optional


class JsonFile:
    def __init__(self, path):
        self.path = path

    def persist(self, key: str, value: any):
        try:
            with open(self.path, "r") as file:
                try:
                    file_data = json.load(file)
                except json.JSONDecodeError:
                    file_data = {}
        except FileNotFoundError:
            file_data = {}
        with open(self.path, "w") as file:
            file_data[key] = value
            json.dump(file_data, file, indent=2)

    def read(self, key: str) -> Optional[any]:
        try:
            with open(self.path, "r") as file:
                data = json.load(file)
                if key in data:
                    return data[key]
                else:
                    return None
        except FileNotFoundError:
            return None

    def remove(self, key: str):
        try:
            with open(self.path, "r") as file:
                try:
                    file_data = json.load(file)
                except json.JSONDecodeError:
                    file_data = {}
            with open(self.path, "w") as file:
                del file_data[key]
                json.dump(file_data, file, indent=2)
        except FileNotFoundError:
            return
