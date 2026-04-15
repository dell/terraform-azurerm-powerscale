# LNN/VM Mapping in Azure-Hosted PowerScale Clusters

## Purpose

This document outlines the LNN/VM name mapping and troubleshooting guidance for potential node name mismatches in Azure-hosted
Isilon (PowerScale) clusters.

## Scope

Applies to all Azure-deployed Isilon clusters, particularly in test and production environments using Terraform-based
deployment.

---

## Understanding LNN and VM Name

### What is LNN?

- **LNN (Logical Node Number)** is a unique identifier assigned by OneFS to each node in the cluster.
- It helps OneFS manage node-specific tasks and data paths.

### What is VM Name?

- **VM Name** is the name of the virtual machine in Azure that runs the OneFS node.
-  It’s used for managing and identifying the node in the Azure portal or CLI.

### What is Internal Node Name?

- The internal node name follows the format: __`<cluster_name>-<LNN>`__
---

## LNN and VM Name Mismatch Explained

### Why It Happens

In Terraform-based deployments, all VM nodes are provisioned in parallel. OneFS assigns Logical Node Numbers (LNNs)
based on **first response** during the join process—not by VM name or creation order. This can lead to mismatches
between VM names and LNNs.

---

### How to Detect It

**Example scenario:** 3-node cluster

| Node Name                   | VM Name                          | Intended Order | Actual Join Order | Assigned LNN |
|-----------------------------|----------------------------------|----------------|-------------------|--------------|
| powerscale-clusterX-node-01 | 5a1ad2hlbc1vyhzyd0659rit0-node-1 | 1              | 1st               | 1            |
| powerscale-clusterX-node-03 | 5a1ad2hlbc1vyhzyd0659rit0-node-2 | 2              | 3rd               | 3            |
| powerscale-clusterX-node-02 | 5a1ad2hlbc1vyhzyd0659rit0-node-3 | 3              | 2nd               | 2            |

### From the OneFs Platform API

From the API we can make the following API call.
```
22/cluster/availability-status
```
This will return a JSON object.

From this we need only need to find a couple of pieces of information per node.

1. The LNN
2. The Azure Node Name (VM name)

The LNN is the Logical Node Number. This is the number that matches the number at the end of the hostname.

The Azure Node Name is the name of the virtual machine in Azure that runs the OneFS node.

### The JSON is of this form:

```json
{
  "all_protocols_available": [
    1,
    2,
    3
  ],
  "down_nodes": 0,
  "external_connectivity": [
    1,
    2,
    3
  ],
  "nodes": [
    {
      "available_drives": [
        0,
        1,
        2,
        3,
        4,
        5
      ],
      "id": 1,
      "instance_id": "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-resource-group/providers/Microsoft.Compute/virtualMachines/5a1ad2hlbc1vyhzyd0659rit0-node-1/",
      "lnn": 1,
      Remaining items removed for clarity.
```

In each of the "node" sections there is a "lnn" (**1**), and an "instance_id" (**"/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-resource-group/providers/Microsoft.Compute/virtualMachines/5a1ad2hlbc1vyhzyd0659rit0-node-1/"**).

Note that there will be 1 node in the nodes array for each node in the cluster. In this case there are 3 nodes. Full sample output is near the bottom of this document

Within the instance id is the Azure Node Name (VM name).

"/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-resource-group/providers/Microsoft.Compute/virtualMachines/**5a1ad2hlbc1vyhzyd0659rit0-node-1**/".

The following is a table of these items made from the output from the OneFs Platform API.

```
lnn  vm_name
1    5a1ad2hlbc1vyhzyd0659rit0-node-1
3    5a1ad2hlbc1vyhzyd0659rit0-node-2
2    5a1ad2hlbc1vyhzyd0659rit0-node-3
```

We see that we have a mismatch between **VM name** and **LNN**.

- LNN 2 is node 2 (powerscale-clusterX-node-02) and is on the VM 5a1ad2hlbc1vyhzyd0659rit0-node-3
- LNN 3 is node 3 (powerscale-clusterX-node-03) and VM name 5a1ad2hlbc1vyhzyd0659rit0-node-2

### Why This Matters During Node Replacement

If a node fails, and you need to replace LNN 2, but mistakenly delete VM 2 (thinking it corresponds to LNN 2), you may:

- **Delete the wrong node**, causing **data loss** or **cluster instability**
- Leave the actual failed node online, while removing a healthy one
- Break the cluster’s fault domain configuration

### How to Prevent Accidental Replacement

- **Always verify LNN-to-VM mapping before** any destructive action.

- Use the following commands to confirm mapping:

```bash
% isi cluster lnnset view
LNN  Device ID  Internal IP Address
------------------------------------
1    1          100.93.41.69
2    3          100.93.41.70
3    2          100.93.41.71
------------------------------------
Total: 3
```

Run `hostname` on each node to confirm the hostname matches the LNN.

- Cross-reference the output with your VM naming convention and Terraform state.

- Maintain a mapping file or documentation that tracks LNN ↔ VM relationships.
- Avoid relying solely on VM names or creation order — always validate with OneFS.

### Mapping Summary

| LNN | Device ID | VM Name  | Hostname                    | Status  |
|-----|-----------|----------------------------------|-----------------------------|---------|
| 1   | 1         | 5a1ad2hlbc1vyhzyd0659rit0-node-1 | powerscale-clusterX-node-01 | Healthy |
| 2   | 3         | 5a1ad2hlbc1vyhzyd0659rit0-node-3 | powerscale-clusterX-node-02 | Failed  |
| 3   | 2         | 5a1ad2hlbc1vyhzyd0659rit0-node-2 | powerscale-clusterX-node-03 | Healthy |


## Useful OneFS CLI Commands

| Command                                                  | Description                            |
|----------------------------------------------------------|----------------------------------------|
| `isi cluster lnnset view`                                | Shows current LNN-to-Device ID mapping |
| `isi cluster lnnset modify <device>-<lnn>`               | Reassigns LNN to a different device    |
| `isi devices node smartfail --node=<lnn>`                | Initiates SmartFail on a node          |
| `isi job status`                                         | Monitors SmartFail progress            |
| `isi status `                                            | Displays overall cluster health        |


## Troubleshooting Tips

- Preserve failed node for RCA — do not delete it prematurely.
- Access Serial Console via Azure Portal → Boot Diagnostics.
- Review Azure activity logs for VM reboots or host maintenance.
- Confirm LNN/VM mapping before any SmartFail or deletion.


## Escalation

Escalate to IME via L2 or SME if RCA or node mapping is unclear.
Provide timeline of customer actions (e.g., VM reboots during Azure host maintenance).

## Best Practices

- Maintain a mapping table of LNNs to VM names and IPs.
- Automate detection of mismatches using scripts or Terraform outputs.
- Always verify LNN before initiating SmartFail or node replacement.
- Include this README in your Terraform repo for quick reference.


## References

- Dell EMC Support: _KB Article: Handling Node Failures in Azure-Hosted Isilon Clusters_
- OneFS CLI Documentation - https://www.dell.com/support/manuals/en-us/isilon-onefs/ifs-pub-91200-administration-guide-cli

## Sample Output from 22/cluster/availability-status
```json
{
  "all_protocols_available": [
    1,
    2,
    3
  ],
  "down_nodes": 0,
  "external_connectivity": [
    1,
    2,
    3
  ],
  "nodes": [
    {
      "available_drives": [
        0,
        1,
        2,
        3,
        4,
        5
      ],
      "id": 1,
      "instance_id": "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-resource-group/providers/Microsoft.Compute/virtualMachines/5a1ad2hlbc1vyhzyd0659rit0-node-1/",
      "lnn": 1,
      "provider_availability_status": {
        "id": "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-resource-group/providers/Microsoft.Compute/virtualMachines/5a1ad2hlbc1vyhzyd0659rit0-node-1/providers/Microsoft.ResourceHealth/availabilityStatuses/current",
        "location": "centralus",
        "name": "current",
        "properties": {
          "availabilityState": "Available",
          "category": "Not Applicable",
          "context": "Not Applicable",
          "occuredTime": "2026-01-26T18:41:39Z",
          "reasonChronicity": "Transient",
          "reasonType": "",
          "reportedTime": "2026-01-28T17:27:53.0994293Z",
          "summary": "There aren't any known Azure platform problems affecting this virtual machine.",
          "title": "Available"
        },
        "type": "Microsoft.ResourceHealth/AvailabilityStatuses"
      },
      "provider_health_events": {
      },
      "state": "UP",
      "uptime": 168349
    },
    {
      "available_drives": [
        0,
        1,
        2,
        3,
        4,
        5
      ],
      "id": 2,
      "instance_id": "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-resource-group/providers/Microsoft.Compute/virtualMachines/5a1ad2hlbc1vyhzyd0659rit0-node-3/",
      "lnn": 3,
      "provider_availability_status": {
        "id": "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-resource-group/providers/Microsoft.Compute/virtualMachines/5a1ad2hlbc1vyhzyd0659rit0-node-3/providers/Microsoft.ResourceHealth/availabilityStatuses/current",
        "location": "centralus",
        "name": "current",
        "properties": {
          "availabilityState": "Available",
          "category": "Not Applicable",
          "context": "Not Applicable",
          "occuredTime": "2026-01-26T18:41:40Z",
          "reasonChronicity": "Transient",
          "reasonType": "",
          "reportedTime": "2026-01-28T17:27:53.1411048Z",
          "summary": "There aren't any known Azure platform problems affecting this virtual machine.",
          "title": "Available"
        },
        "type": "Microsoft.ResourceHealth/AvailabilityStatuses"
      },
      "provider_health_events": {
      },
      "state": "UP",
      "uptime": 168347
    },
    {
      "available_drives": [
        0,
        1,
        2,
        3,
        4,
        5
      ],
      "id": 3,
      "instance_id": "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-resource-group/providers/Microsoft.Compute/virtualMachines/5a1ad2hlbc1vyhzyd0659rit0-node-2/",
      "lnn": 2,
      "provider_availability_status": {
        "id": "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-resource-group/providers/Microsoft.Compute/virtualMachines/5a1ad2hlbc1vyhzyd0659rit0-node-2/providers/Microsoft.ResourceHealth/availabilityStatuses/current",
        "location": "centralus",
        "name": "current",
        "properties": {
          "availabilityState": "Available",
          "category": "Not Applicable",
          "context": "Not Applicable",
          "occuredTime": "2026-01-26T18:41:41Z",
          "reasonChronicity": "Transient",
          "reasonType": "",
          "reportedTime": "2026-01-28T17:27:53.0310421Z",
          "summary": "There aren't any known Azure platform problems affecting this virtual machine.",
          "title": "Available"
        },
        "type": "Microsoft.ResourceHealth/AvailabilityStatuses"
      },
      "provider_health_events": {
      },
      "state": "UP",
      "uptime": 168346
    }
  ],
  "total": 3,
  "total_nodes": 3,
  "up_nodes": 3
}
```
