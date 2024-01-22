#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
This is the master script that runs through training, validation, and final model creation.

Run this script after the latest round of data updates to confirm preferred model performs best.
"""

import explore_classification
import explore_regression

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# TODO's
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# TODO: add tuning script
# TODO: add prediction step

# Rerunning classification models
explore_classification.rerun()

# Rerunning regression models
explore_regression.rerun()