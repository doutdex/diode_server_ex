#!/bin/bash
# Diode Server
# Copyright 2019 IoT Blockchain Technology Corporation LLC (IBTC)
# Licensed under the Diode License, Version 1.0
find ./clones/* ./data_*/blockchain.sq3* ./data_*/cache.sq3 -maxdepth 1 -type f -delete
make clean
