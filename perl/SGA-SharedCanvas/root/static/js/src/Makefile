BUILD_DIR = build
SRC_DIR = .
COFFEE = /usr/local/bin/coffee

BASE_FILES = util.coffee \
	model.coffee \
	component.coffee \
	presentation.coffee \
        template.coffee \
	application.coffee \
	instance.coffee \
        modals.coffee

MODULES = intro.coffee \
	${BASE_FILES} \
	outro.coffee

APP = sga.js
APP_MIN = sga.min.js
APP_C = sga.coffee

all: ${APP}

${APP_C}: ${MODULES}
	@@echo "Building sga.coffee..."
	@@rm -f ${APP_C}.tmp
	@@for i in ${BASE_FILES}; do \
		cat $$i | sed 's/^/  /' >> ${APP_C}.tmp; \
		echo >> ${APP_C}.tmp; \
		done
	@@cat ${SRC_DIR}/intro.coffee ${APP_C}.tmp ${SRC_DIR}/outro.coffee > ${APP_C}
	@@rm -f ${APP_C}.tmp;

${APP}: ${APP_C}
	@@${COFFEE} -c ${APP_C}
	@@cp ${APP} ../application.js

