#!/usr/bin/python3

import os
import executor

from dotenv import load_dotenv
load_dotenv()

class ADOClient:
  def __init__(self, subscription, org, project):
    self._subscription = subscription
    self._org = org
    self._project = project

  def _execute(self, command):
    command = "az " + command
    command += " --subscription " + self._subscription
    """command += " --project " + self._project"""
    command += " --organization https://dev.azure.com/" + self._org

    result = executor.execute(command, capture=True)
    print(result)

  def create_work_item(self, work_item):
    command = "boards work-item create"

  def show_work_item(self, work_item_id):
    command = "boards work-item show"
    command += " --id " + str(work_item_id)
    self._execute(command)

"""
for line in open("ado_export.csv").readlines():
  ado.create_item()
"""

SUBSCRIPTION = os.environ["SUBSCRIPTION"]
PROJECT = os.environ["PROJECT"]
ORG = os.environ["ORG"]

ado = ADOClient(SUBSCRIPTION, ORG, PROJECT)
ado.show_work_item(931)
