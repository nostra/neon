#!/usr/bin/env sh

LOG_FILE=/tmp/neoncode-trigger-$(date +%Y-%m-%d).log

echo ">>> Triggered at $(date) ">> $LOG_FILE
# This will output last log line: git log -1 >> $LOG_FILE

echo 'POST / HTTP/1.1
Host: el-neon-listener.neon-builder
Content-Type: application/json
Content-Length: 24

{"reponame": "neoncode"}
' | nc el-neon-listener.neon-builder 8080 >> $LOG_FILE 2>&1

echo "<<< Finished at $(date) ">> $LOG_FILE
echo ">>> Triggered build <<<"