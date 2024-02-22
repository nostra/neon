#!/usr/bin/env sh

LOG_FILE=/tmp/webhook-trigger-$(date +%Y-%m-%d).log

echo ">>> Triggered at $(date) ">> $LOG_FILE
# This will output last log line: git log -1 >> $LOG_FILE

WEBHOOK_PATH=hook/12c23743657f5f2550bbcc88c90903ac6653265a031b54ae08c430a1dcc4e396
curl -s http://webhook-receiver.flux-system/$WEBHOOK_PATH >> $LOG_FILE 2>&1

echo "<<< Finished at $(date) ">> $LOG_FILE
echo ">>> Triggered webhook <<<"