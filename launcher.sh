#!/bin/bash

export QML_IMPORT_PATH="/usr/share/chillpill-shell:$QML_IMPORT_PATH"
exec qs -p /usr/share/chillpill-shell
