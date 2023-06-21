import sys

from setuptools import find_packages, setup
from setuptools.command.test import test as TestCommand

PACKAGE_TYPE = 'pg-tools'
PACKAGE_NAME = 'pg-export'
PACKAGE_DESC = 'pg to git converter'
PACKAGE_LONG_DESC = 'Convert postgres database to directory with object files'
PACKAGE_VERSION = '3.6.0'


class PyTest(TestCommand):

    user_options = [('pytest-args=', 'a', "Arguments to pass to pytest")]

    def initialize_options(self):
        super().initialize_options()
        # default list of options for testing
        # https://docs.pytest.org/en/latest/logging.html
        self.pytest_args = (
            '--flake8 {0} tests examples '
            '--junitxml=.reports/{0}_junit.xml '
            '--cov={0} --cov=tests '
            '-p no:logging'.format(PACKAGE_NAME.replace('-', '_'))
        )

    def run_tests(self):
        import shlex
        # import here, cause outside the eggs aren't loaded
        import pytest
        errno = pytest.main(shlex.split(self.pytest_args))
        sys.exit(errno)


setup_requires = []

install_requires = [
    'aiofiles>=0.7',
    'Jinja2>=3.0',
    'asyncpg==0.27.0'
]

tests_require = [
    'flake8==3.8.3',
    'pytest==5.4.3',
    'pytest-cov==2.9.0',
    'pytest-flake8==1.0.6',
    'pytest-asyncio==0.12.0',
    'asynctest==0.13.0',
    'importlib-metadata<5.0',
]

console_scripts = [
    'pg_export=pg_export.main:main'
]

setup(
    name=PACKAGE_NAME,
    version=PACKAGE_VERSION,
    description=PACKAGE_DESC,
    long_description=PACKAGE_LONG_DESC,
    url='https://git.dev.uiscom.ru/{}/{}'.format(PACKAGE_TYPE, PACKAGE_NAME),
    author="Andrey Chernyakov",
    author_email="a.chernyakov@comagic.dev",
    license="Nodefined",
    classifiers=[
        'Development Status :: 5 - Production/Stable',
        'Environment :: Console',
        'Framework :: Pytest',
        'Intended Audience :: Customer Service',
        'Intended Audience :: Information Technology',
        'License :: Other/Proprietary License',
        'License :: UIS License',
        'Natural Language :: Russian',
        'Natural Language :: English',
        'Operating System :: POSIX',
        'Programming Language :: Python :: 3.5',
        'Programming Language :: Python :: 3.6',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9',
    ],
    zip_safe=False,
    packages=find_packages(exclude=['tests', 'examples', '.reports']),
    entry_points={'console_scripts': console_scripts},
    python_requires='>=3.5',
    setup_requires=setup_requires,
    install_requires=install_requires,
    tests_require=tests_require,
    cmdclass={'test': PyTest},
    include_package_data=True
)
