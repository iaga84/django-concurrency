VERSION=2.0.0
BUILDDIR='~build'
DJANGO_SETTINGS_MODULE:=demoproject.settings
PYTHONPATH := ${PWD}/demo/:${PWD}
PIP=${VIRTUAL_ENV}/bin/pip
DJANGO_14=django==1.4.8
DJANGO_15=django==1.5.4
DJANGO_16=https://www.djangoproject.com/m/releases/1.6/Django-1.6b4.tar.gz
DJANGO_DEV=git+git://github.com/django/django.git


mkbuilddir:
	mkdir -p ${BUILDDIR}

install-deps:
	pip install -r demo/demoproject/requirements.pip -r requirements.pip python-coveralls coverage


locale:
	cd concurrency && django-admin.py makemessages -l en
	export PYTHONPATH=${PYTHONPATH}
	cd concurrency && django-admin.py compilemessages --settings=${DJANGO_SETTINGS_MODULE}

docs: mkbuilddir
	sphinx-build -aE docs ${BUILDDIR}/docs
	firefox ${BUILDDIR}/docs/index.html

test:
	demo/manage.py test concurrency --settings=${DJANGO_SETTINGS_MODULE}


init-db:
	@sh -c "if [ '${DBENGINE}' = 'mysql' ]; then mysql -e 'DROP DATABASE IF EXISTS concurrency;'; fi"
	@sh -c "if [ '${DBENGINE}' = 'mysql' ]; then pip install MySQL-python; fi"
	@sh -c "if [ '${DBENGINE}' = 'mysql' ]; then mysql -e 'create database IF NOT EXISTS concurrency;'; fi"

	@sh -c "if [ '${DBENGINE}' = 'pg' ]; then psql -c 'DROP DATABASE IF EXISTS concurrency;' -U postgres; fi"
	@sh -c "if [ '${DBENGINE}' = 'pg' ]; then psql -c 'DROP DATABASE IF EXISTS test_concurrency;' -U postgres; fi"
	@sh -c "if [ '${DBENGINE}' = 'pg' ]; then psql -c 'CREATE DATABASE concurrency;' -U postgres; fi"
	@sh -c "if [ '${DBENGINE}' = 'pg' ]; then pip install -q psycopg2; fi"

ci:
	@sh -c "if [ '${DJANGO}' = '1.4.x' ]; then pip install ${DJANGO_14}; fi"
	@sh -c "if [ '${DJANGO}' = '1.5.x' ]; then pip install ${DJANGO_15}; fi"
	@sh -c "if [ '${DJANGO}' = '1.6.x' ]; then pip install ${DJANGO_16}; fi"
	@sh -c "if [ '${DJANGO}' = 'dev' ]; then pip install ${DJANGO_DEV}; fi"
	@pip install coverage
	@python -c "from __future__ import print_function;import django;print('Django version:', django.get_version())"
	@echo "Database:" ${DBENGINE}

	coverage run demo/manage.py test concurrency --noinput --settings=${DJANGO_SETTINGS_MODULE} --failfast
	#demo/manage.py test concurrency --settings=${DJANGO_SETTINGS_MODULE} --noinput


coverage: mkbuilddir
	coverage report
	coverage html

clean:
	rm -fr ${BUILDDIR} dist *.egg-info .coverage
	find . -name __pycache__ -o -name "*.py?" -o -name "*.orig" -prune | xargs rm -rf
	find concurrency/locale -name django.mo | xargs rm -f

.PHONY: docs test
