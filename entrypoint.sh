#!/bin/bash

set -eu

USER_PUID="${PUID:-1000}"
USER_PGID="${PGID:-1000}"
USER_NAME="user"
USER_GROUP="user"
USER_HOME="/home/${USER_NAME}"

function log_prefix() {
    echo "[entrypoint]"
}

function log_info() {
    local prefix="$(log_prefix)"
    echo "${prefix} INFO ${1}"
}

function log_error() {
    local prefix="$(log_prefix)"
    echo "${prefix} ERROR ${1}"
}

function user_setup() {
    if [ "${USER_PUID}" -eq 0 ] && [ "${USER_PGID}" -eq 0 ]; then
        log_info "running as root:root"
        return 0
    fi

    if getent group "${USER_GROUP}" >/dev/null 2>&1; then
        current_pgid=$(getent group "${USER_GROUP}" | cut -d':' -f3)
        if [ "${USER_PGID}" -ne "${current_pgid}" ]; then
            log_info "changing group: ${USER_GROUP} (PGID=${USER_PGID})"
            groupmod -g "${USER_PGID}" "${USER_GROUP}"
        fi
    else
        log_error "group doesn't exist: ${USER_GROUP}"
        exit 1
    fi

    if id -u "${USER_NAME}" >/dev/null 2>&1; then
        current_puid=$(id -u "${USER_NAME}")
        if [ "${USER_PUID}" -ne "${current_puid}" ]; then
            log_info "changing user: ${USER_NAME} (PUID=${USER_PUID})"
            usermod -u "${USER_PUID}" "${USER_NAME}"
        fi
    else
        log_error "user doesn't exist: ${USER_PUID}"
        exit 1
    fi
}

function check_inputs() {
    if [ ! -v WORK_DIR ]; then
        log_error "WORK_DIR is undefined"
        exit 1
    fi

    if [ ! -d "${WORK_DIR}" ]; then
        log_error "WORK_DIR doesn't exist: ${WORK_DIR}"
        exit 1
    fi
}

check_inputs
user_setup

cd "${WORK_DIR}" || exit 1

exec gosu ${USER_PUID}:${USER_PGID} "${@}"
