# TF config to set up remote state in Azure Blob Storage

## Overview

This is a TF config to create a blob storage account and generate a SAS token to allow terraform to use remote state.

## Usage

1. apply the `main.tf` to your environment (only needs to be done once per env!)
2. sanity check the output which will be in `backend-config.txt`
3. Migrate state to remote by running:

```bash
terraform init -backend-config=backend-config.txt
```