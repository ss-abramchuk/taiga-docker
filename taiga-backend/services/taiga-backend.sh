#!/bin/bash -e

echo "Start taiga backend"
exec passenger start /home/app/taiga/backend
