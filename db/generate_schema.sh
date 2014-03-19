#!/bin/bash

dbicdump -o dump_directory=./lib -o components='["InflateColumn::DateTime"]' KohaProfile::Schema dbi:mysql:kohaprofile kohaprofile pass
