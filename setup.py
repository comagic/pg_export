import os

from distutils.core import setup

def read(fname):
    with open(os.path.join(os.path.dirname(__file__), fname)) as f:
        return f.read()

def get_packages(dirs):
    packages = []
    for dir in dirs:
        for dirpath, dirnames, filenames in os.walk(dir):
            if '__init__.py' in filenames:
                packages.append(dirpath)
    return packages

setup(name = "pg_export",
      description="pg_dump -> repo",
      license="""uiscom license""",
      version = "0.4",
      maintainer = "Dima Beloborodov",
      maintainer_email = "d.beloborodov@ulab.ru",
      url = "http://uiscom.ru",
      scripts = ['bin/pg_export'],
      packages = get_packages(['pg_export']))
