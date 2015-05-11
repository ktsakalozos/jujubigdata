PROJECT=jujubigdata
SPHINX := /usr/bin/sphinx-build
SUITE=unstable
TESTS=tests/

.PHONY: all
all:
	@echo "make test"
	@echo "make source - Create source package"
	@echo "make clean"
	@echo "make userinstall - Install locally"
	@echo "make docs - Build html documentation"
	@echo "make release - Build and upload package and docs to PyPI"

.PHONY: source
source: setup.py
	scripts/update-rev
	python setup.py sdist

.PHONY: clean
clean:
	-python setup.py clean
	find . -name '*.pyc' -delete
	rm -rf dist/*
	rm -rf .venv
	rm -rf .venv3
	rm -rf docs/_build

.PHONY: docclean
docclean:
	-rm -rf docs/_build

.PHONY: userinstall
userinstall:
	scripts/update-rev
	python setup.py install --user

.venv:
	- [ -z "`dpkg -l | grep python-virtualenv`" ] && sudo apt-get install -y python-virtualenv
	virtualenv .venv
	.venv/bin/pip install -IUr test_requirements.txt

.venv3:
	- [ -z "`dpkg -l | grep python-virtualenv`" ] && sudo apt-get install -y python-virtualenv
	virtualenv .venv3 --python=python3
	.venv3/bin/pip install -IUr test_requirements.txt

# Note we don't even attempt to run tests if lint isn't passing.
.PHONY: test
test: lint test2 test3

.PHONY: test2
test2:
	@echo Starting Py2 tests...
	.venv/bin/nosetests -s --nologcapture tests/

.PHONY: test3
test3:
	@echo Starting Py3 tests...
	.venv3/bin/nosetests -s --nologcapture tests/

.PHONY: ftest
ftest: lint
	@echo Starting fast tests...
	.venv/bin/nosetests --attr '!slow' --nologcapture tests/
	.venv3/bin/nosetests --attr '!slow' --nologcapture tests/

.PHONY: lint
lint: .venv .venv3
	@echo Checking for Python syntax...
	@flake8 --max-line-length=120 $(PROJECT) $(TESTS) \
	    && echo Py2 OK
	@python3 -m flake8.run --max-line-length=120 $(PROJECT) $(TESTS) \
	    && echo Py3 OK

.PHONY: docs
docs: .venv
	- [ -z "`.venv/bin/pip list | grep -i 'sphinx '`" ] && .venv/bin/pip install sphinx
	- [ -z "`.venv/bin/pip list | grep -i sphinx-pypi-upload`" ] && .venv/bin/pip install sphinx-pypi-upload
	cd docs && make html SPHINXBUILD="../.venv/bin/python $(SPHINX)" && cd -

.PHONY: docrelease
docrelease: .venv docs
	.venv/bin/python setup.py register upload_docs

.PHONY: release
release: .venv docs
	scripts/update-rev
	.venv/bin/python setup.py register sdist upload upload_docs
