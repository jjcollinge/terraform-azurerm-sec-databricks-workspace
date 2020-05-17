# Working Practices - BRIGHTSIDE

CSE DevCrews prefer to work in customer-managed Azure subscriptions and work-tracking systems wherever possible. 

This is not feasible for the BRIGHTSIDE project. The customer requires MSFT personnel collaborating to have certain 
statuses in order to access the customer-managed subscriptions and work-tracking systems. This requirement is in place 
primarly to protect the customer's intellectual property which can include the fact that a collaboration is ongoing.
The required statuses are not universally present amongst all DevCrew members.

In order to allow efficient collaboration between the two organisations an alternative set of working practices 
is described below which is hoped will enable both organisations to contribute fully to the succes of the project 
whilst respecting the customer's confidentiality requirements.

For the remainder of this document we have assumed:

 - Azure DevOps (ADO) is both the work-tracking and the CI/CD system.
 - Source code repositories are GIT, hosted in in ADO.


The following hard requirements are in place and inform this set of working practices:

 - MSFT staff not having required status will never be able to access the customer subscription.
   - This includes work-tracking, source code and deployments.
 - Customer can access MSFT hosted ADO & source code
 - The collaboration between the two organisations is itself IP that the customer wishes to protect
   - This includes constraining knowledge of the collaboration to MSFT staff known to the customer
 - The ultimate destination of deployed artifacts is the customer subscription


## Working Practices - Work Item Tracking

ADO is the selected work item tracking system.

- MSFT will create a unique ADO organisation (org) for the project
- That org will only contain persons contributing to the project
- The existence and membership of that org will never be revealed to persons not in the org
- Customer staff will be invited to the org
- Customer PO will have Co-admin rights
- Other customer staff will have Contributor rights
- The customer is only ever referred to as 'the customer' within work items
- MSFT staff in that org will have a variety of statuses
  - Therefore this org and the projects and work items within it are considered LOW-side
- Customer may maintain a parallel ADO within their own subscription
- A periodic, as-required one-way transfer of items between MSFT and Customer ADO may occur
- Day-to-day collaboration occurs only on the MSFT-hosted ADO instance
 - This means that PRs, documentation etc contributed to the project by MSFT team will always created in and in reference to the MSFT-hosted ADO.


## Working Practices - Source Code Management

Git within ADO is the selected source code management system (the repo).

- Access to the repo is controlled by ADO membership
- Access is strictly limited to that membership
  - This explicitly include read and discovery permissions
- SSH pubkey is the only accepted method of authorisation
- MSFT staff are required to use unique SSH credentials to access the repo
- Usual branch, review, PR policies are in place:
  - Branch per story/task (as appropriate)
  - Merge to master only by PR
  - PR's require 2 reviews, must be linked to a work item
  - CI/CD must be green before a merge to master can occur
- Customer will fork the MSFT-hosted repo
  - Only linkage therefore is customer -> MSFT
  - Customer will periodically catch up by usual Git operations
  - MSFT will not attempt to track merges happening in customer repo
  - Customer must therefore take responsibility for dealing with conflicts
    - MSFT team with required may assist as appropriate

## Working Practices - CI/CD

Azure Pipelines within ADO is the selected CI/CD system

- CI/CD is described in the usual manner as a .yml file within the repo
- The identity (assumed to be a service principal) under which CI/CD tasks are performed is provided via the standard pipeline variable system
- MSFT and customer team maintain a separate set of pipeline variables authorised only to their own susbcriptions
- Infrastructure requirements are described via Terraform.
- Infrastructure tests will utilise Terratest
- Once the initial bootstrapping commits are in place all merges to master will require succesful CI run to succeed.
- MSFT staff with required status may assist customer debugging pipeline issues in their subscription
- MSFT team will not, by default, have access to the customer environment
- Customer team have full access to their own environment and may conduct whatever user acceptance testing they deem appropriate



