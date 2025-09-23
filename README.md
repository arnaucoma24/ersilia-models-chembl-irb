# ersilia-models-chembl-irb
Running Ersilia models on ChEMBL v.36 compounds at the IRB cluster

## Prerequisites

The ChEMBL database must be installed locally before running any script in this repository. You can follow the installation guidelines described in the [chembl-antimicrobial-tasks](https://github.com/ersilia-os/chembl-antimicrobial-tasks/tree/main) repository.

## Steps

1. Getting compounds with reported bioactivity on the ChEMBL database. Splitting compounds in batches of 10,000. 

2. Copy all contents from `data` to the `aloy/home`