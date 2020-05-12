#!/usr/bin/python3

import os
import sys
import csv
import json
import executor
import concurrent.futures

from dotenv import load_dotenv
load_dotenv()

ADO_RESOURCE="499b84ac-1321-427f-aa17-267ca6975798"

"""
ado.show_work_item(1065)
ado.create_work_item("Task", "TestTask")
result = json.loads(ado.query("Select [Id] From WorkItems WHERE [Work Item Type] = \'Task\' AND [System.Tags] Contains Words \'auto\'"))
result = json.loads(ado.query("Select [Id] FROM WorkItems WHERE [System.Tags] Contains Words \'#auto\'"))

work_item_ids = [item["id"] for item in result["workItems"]]
work_items = ado.get_work_items_batch(work_item_ids, ["System.Title"])
work_items = ado.get_work_items_batch(work_item_ids, ["System.Title", "System.Tags"])
work_item_ids = [item["id"] for item in work_items]
for _id in work_item_ids:
  ado.delete_work_item(_id)
"""



class ADOClient:

  class WorkItemIterator:
    """ Iterator returning batches of _item_limit=200 ids per call for use in
        batch function (since API limit)
    """
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

  LINK_TYPES = {
    "parent" : "System.LinkTypes.Hierarchy-Reverse",
    "child" : "System.LinkTypes.Hierarchy-Forward"
  }

  @staticmethod
  def _get_link_name(link_type):
    try:
      return ADOClient.LINK_TYPES[link_type]
    except IndexError:
      return ""

  def __init__(self, subscription, org, project):
    self._subscription = subscription
    self._org = org
    self._project = project

  def _execute(self, command):
    cmd = executor.ExternalCommand(command, capture = True, capture_stderr = True, check = True)
    cmd.start()
    cmd.wait()
    if not cmd.succeeded:
      print(cmd.stderr, file=sys.stderr)
      return False
    return cmd.stdout

  def _execute_ado(self, command):
    command = "az " + command
    command += " --subscription " + self._subscription
    command += " --organization https://dev.azure.com/" + self._org
    return self._execute(command)
  
  def _execute_rest(self, command):
    command = "az " + command
    command += " --subscription " + self._subscription
    command += f" --resource {ADO_RESOURCE}"
    return self._execute(command)

  def work_item_show(self, work_item_id):
    command = "boards work-item show"
    command += " --id " + str(work_item_id)
    return json.loads(self._execute_ado(command))

  def work_item_get_batch(self, work_item_ids, fields = None):
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

  def work_item_create(self, task_type, title, fields = {}):
    command = "boards work-item create"
    fields["System.Tags"] = "#auto"
    command += " --project " + self._project
    command += " --type \"" + task_type + "\""
    command += " --title \"" + title + "\""
    command += " --fields"
    for k,v in fields.items():
      command += " " + str(k) + "=\"" + str(v) + "\""
    work_item = json.loads(self._execute_ado(command))
    return work_item

  def work_item_update(self, work_item_id, fields = {}):
    command = "boards work-item update"
    command += " --id " + str(work_item_id)
    command += " --fields"
    for k,v in fields.items():
      command += " " + str(k) + "=\"" + str(v) + "\""
    work_item = json.loads(self._execute_ado(command))
    return work_item

  def work_item_add_link(self, work_item_id, link_type, other_item_id, link_name = ""):
    command = "rest"
    command += " --method PATCH"
    command += " --uri https://dev.azure.com/" + self._org
    command += "/_apis/wit/workitems/" + str(work_item_id) + "?api-version=5.1"
    command += " --headers content-type=application/json-patch+json"

    if link_type in ADOClient.LINK_TYPES.keys():
      link_name = link_type
      link_type = ADOClient.LINK_TYPES[link_name]

    body = [{
      "op" : "add", 
      "path" : "/relations/-", 
      "value" : { 
        "rel" : link_type,
        "url" : "https://dev.azure.com/" + self._org + "/_apis/wit/workItems/" + str(other_item_id),
        "attributes" : { "comment" : "#auto",  "isLocked" : False, "name" : link_name },
      }
    }]

    command += " --body " + repr(json.dumps(body))
    return self._execute_rest(command)

  def work_item_delete(self, work_item_id):
    command = "boards work-item delete"
    command += " --id " + str(work_item_id)
    command += " --project " + self._project
    command += " --yes "
    return self._execute_ado(command)

  def work_item_query(self, wiql):
    command = "rest"
    command += " --method POST"
    command += " --uri https://dev.azure.com/" + self._org + "/_apis/wit/wiql?api-version=5.1"
    command += " --body \"{ \\\"query\\\" : \\\"" + wiql + "\\\" }\""
    return self._execute_rest(command)


def get_source_work_items_from_csv(file_path = "./ado_export.csv"):

  """
    Read completely and return as a list of objects a CSV export from source ADO
  """

  fields = {}
  work_items = []
  first_row = True
  with open(file_path, encoding='utf-8-sig') as f:

    csv_reader = csv.reader(f)
    for row in csv_reader:
      
      index = 0

      if first_row:
        # First row is field names
        first_row = False
        for field in row:
          fields[index] = field.strip().lower()
          index += 1
        continue
   
      # Collate all the source work items 
      work_item = {}
      for field in row:
        work_item[fields[index]] = field.replace("\"", "")
        index += 1
      work_items.append(work_item)
  return work_items


#############

source_work_items = get_source_work_items_from_csv()

SUBSCRIPTION = os.environ["SUBSCRIPTION"]
PROJECT = os.environ["PROJECT"]
ORG = os.environ["ORG"]

ado = ADOClient(SUBSCRIPTION, ORG, PROJECT)

# 
# Queue up item creation in target ADO, recording parentage as we go

id_map = {} # Map source id to target id
parentage = [] # [(parent, child), ...] in source id space
with concurrent.futures.ThreadPoolExecutor(max_workers = 32) as futures:

  for work_item in source_work_items:

    # Remove and cache non 'field' members
    work_item_id = work_item.pop("id")
    work_item_type = work_item.pop("work item type")
    work_item_title = f"({work_item_id}) " + work_item.pop("title")
    work_item_parent = work_item.pop("parent")

    # Record any parent relationship in source items
    if work_item_parent:
      parentage.append((work_item_id, work_item_parent))
    
    # Schedule concurrent work item creation, map result to original work_item_id
    id_map[work_item_id] = futures.submit(ado.work_item_create, work_item_type, work_item_title, work_item)

  #
  # Fire off concurrent item creation

  failed = 0
  completed = 0
  print("Creating " + str(len(id_map)) + " new work items..")
  for result in concurrent.futures.as_completed(id_map.values()):
    if result.exception():
      failed += 1
      print(result.exception(), file=sys.stderr)
    else:
      completed += 1
    print("\r" + str(completed) + " items created (failed=" + str(failed) + ")", end='')
  print("\nComplete")

  if failed:
    print("Creation of some work items failed, cannot guarantee consistency.\nExiting...")
    sys.exit(1)

# 
# Recreate parent relationships using the newly created ids

print("Reparenting..")
for parent in parentage:
  print(parent[0] + " <- " + parent[1]) 
  ado.work_item_add_link(id_map[parent[0]].result()["id"], "parent", id_map[parent[1]].result()["id"])
