#!/bin/bash

# This script will get all indices older than 30 days (as described by their index name) and dump them to a file
# it can be used as the input to the backup script

curator_cli --config ./curator.yaml show_indices --filter_list \
'[
    {
    "filtertype":"age",
    "source":"name",
    "direction":"older",
    "timestring":"'%Y.%m.%d'",
    "unit":"days",
    "unit_count":"30"
    }
]'
