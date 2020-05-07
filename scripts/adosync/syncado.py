#!/usr/bin/python3

import os
import json
import executor

from dotenv import load_dotenv
load_dotenv()

ADO_RESOURCE="499b84ac-1321-427f-aa17-267ca6975798"

class WorkItemIterator:
  def __init__(self, items):
    self._items = items
    self._item_limit = 200

  def __iter__(self):
    return self

  def __next__(self):
    if len(self._items) == 0:
      raise StopIteration
    items = self._items[:self._item_limit]
    self._items = self._items[self._item_limit:]
    return items


class ADOClient:

  def __init__(self, subscription, org, project):
    self._subscription = subscription
    self._org = org
    self._project = project

  def _execute_ado(self, command):
    command = "az " + command
    command += " --subscription " + self._subscription
    command += " --organization https://dev.azure.com/" + self._org

    result = executor.execute(command, capture=True)
    return result
  
  def _execute_rest(self, command):
    command = "az " + command
    command += " --subscription " + self._subscription
    command += f" --resource {ADO_RESOURCE}"
    result = executor.execute(command, capture=True)
    return result

  def show_work_item(self, work_item_id):
    command = "boards work-item show"
    command += " --id " + str(work_item_id)
    self._execute_ado(command)

  def get_work_items_batch(self, work_item_ids, fields = None):
    results = []
    for item_ids in iter(WorkItemIterator(work_item_ids)):
      command = "rest"
      command += " --method POST"
      command += " --uri https://dev.azure.com/" + self._org + "/_apis/wit/workitemsbatch?api-version=5.1"
      body = {"ids" : item_ids}
      if fields:
        body["fields"] = fields
      command += " --body " + repr(json.dumps(body))
      results.append(json.loads(self._execute_rest(command))["value"])
    return [item for result in results for item in result]

  def create_work_item(self, task_type, title, fields = {}):
    command = "boards work-item create"
    fields["System.Tags"] = "#auto"
    command += " --project " + self._project
    command += " --type " + task_type
    command += " --title \"" + title + "\""
    command += " --fields"
    for k,v in fields.items():
      command += " " + k + "=\"" + v + "\""
    self._execute_ado(command)

  def delete_work_item(self, work_item_id):
    command = "boards work-item delete"
    command += " --id " + str(work_item_id)
    command += " --project " + self._project
    command += " --yes "
    return self._execute_ado(command)

  def query(self, wiql):
    command = "rest"
    command += " --method POST"
    command += " --uri https://dev.azure.com/" + self._org + "/_apis/wit/wiql?api-version=5.1"
    command += " --body \"{ \\\"query\\\" : \\\"" + wiql + "\\\" }\""
    return self._execute_rest(command)



SUBSCRIPTION = os.environ["SUBSCRIPTION"]
PROJECT = os.environ["PROJECT"]
ORG = os.environ["ORG"]

ado = ADOClient(SUBSCRIPTION, ORG, PROJECT)
#ado.show_work_item(1065)
#ado.create_work_item("Task", "TestTask")
#result = json.loads(ado.query("Select [Id] From WorkItems WHERE [Work Item Type] = \'Task\' AND [System.Tags] Contains Words \'auto\'"))
#result = json.loads(ado.query("Select [Id] FROM WorkItems WHERE [System.Tags] Contains Words \'#auto\'"))

#work_item_ids = [item["id"] for item in result["workItems"]]
#work_items = ado.get_work_items_batch(work_item_ids, ["System.Title"])
#work_items = ado.get_work_items_batch(work_item_ids, ["System.Title", "System.Tags"])
#work_item_ids = [item["id"] for item in work_items]
#for _id in work_item_ids:
#  ado.delete_work_item(_id)

for line in open("ado_export.csv").readlines():
  ado.create_work_item()
