#!/bin/bash -e

echo "Start taiga events"
exec passenger start /home/app/taiga/events
