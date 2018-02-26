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
      license="""BSD""",
      version = "0.5.0",
      maintainer = "Dima Beloborodov",
      maintainer_email = "d.beloborodov@gmail.com",
      url = "http://comagic.ru",
      scripts = ['bin/pg_export'],
      packages = get_packages(['pg_export']),
      install_requires = [
          "psycopg2"
      ])
