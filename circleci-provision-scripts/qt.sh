#!/bin/bash

function install_qt() {
    add-apt-repository -y ppa:beineri/opt-qt551-trusty
    apt-get update
    apt-get install qt55base qt55webkit libegl1-mesa-dev

    echo 'source /opt/qt55/bin/qt55-env.sh' >> ${CIRCLECI_HOME}/.circlerc
}
