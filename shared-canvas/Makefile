# based on the Makefile for jquery

SRC_DIR = src
TEST_DIR = test
BUILD_DIR = build

PREFIX = .
DIST_DIR = ${PREFIX}/dist

JS_ENGINE ?= `which node nodejs`
COMPILER = ${JS_ENGINE} ${BUILD_DIR}/uglify.js --unsafe
POST_COMPILER = ${JS_ENGINE} ${BUILD_DIR}/post-compile.js
DOCCO ?= `which docco`

BASE_FILES = ${SRC_DIR}/core.coffee \
			${SRC_DIR}/data.coffee \
			${SRC_DIR}/presentation.coffee \
			${SRC_DIR}/controller.coffee

MODULES = ${SRC_DIR}/intro.coffee \
		${BASE_FILES} \
		${SRC_DIR}/outro.coffee

SC = ${DIST_DIR}/shared-canvas.js
SC_MIN = ${DIST_DIR}/shared-canvas.min.js
SC_C = ${DIST_DIR}/shared-canvas.coffee

SC_VER = $(shell cat version.txt)
VER = sed "s/@VERSION/${SC_VER}/"

DATE=$(shell git log --pretty=format:%ad | head -1)

all: core docs

core: shared-canvas min lint
		@@echo "shared-canvas build complete"

${DIST_DIR}:
		@@mkdir -p ${DIST_DIR}

docs: ${SC_C}
		@@${DOCCO} ${SC_C}

shared-canvas: ${SC}

${SC_C}: ${MODULES} | ${DIST_DIR}
		@@echo "Building" ${SC_C}
		
		@@rm -f ${SC_C}.tmp;
		@@for i in ${BASE_FILES}; do \
			cat $$i | sed 's/^/		/' >> ${SC_C}.tmp; \
			echo >> ${SC_C}.tmp; \
			done
		
		@@cat ${SRC_DIR}/intro.coffee ${SC_C}.tmp ${SRC_DIR}/outro.coffee | \
			sed 's/@DATE/'"${DATE}"'/' | \
			${VER} > ${SC_C};
		@@rm -f ${SC_C}.tmp;

${SC}: ${SC_C}
		@@coffee -c ${SC_C};

lint: shared-canvas
		@@if test ! -z ${JS_ENGINE}; then \
				echo "Checking shared-canvas against JSLint..."; \
				${JS_ENGINE} build/jslint-check.js; \
		else \
				echo "You must have NodeJS installed in order to test shared-canvas against JSLint."; \
		fi

min: shared-canvas ${SC_MIN}

${SC_MIN}: ${SC}
		@@if test ! -z ${JS_ENGINE}; then \
				echo "Minifying shared-canvas" ${SC_MIN}; \
				${COMPILER} ${SC} > ${SC_MIN}.tmp; \
				${POST_COMPILER} ${SC_MIN}.tmp > ${SC_MIN}; \
				rm -f ${SC_MIN}.tmp; \
		else \
				echo "You must have NodeJS installed in order to minify shared-canvas."; \
		fi

clean:
		@@echo "Removing Distribution directory:" ${DIST_DIR}
		@@rm -rf ${DIST_DIR}

distclean: clean

.PHONY: all shared-canvas lint min clean distclean core
