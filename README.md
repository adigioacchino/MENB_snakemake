# What is this repository for?
This repository contains the code to reproduce the results of the paper "Deciphering the code of viral-host adaptation through maximum entropy models".
It is organized as a [Snakemake](https://snakemake.github.io/) workflow, with [Pluto](https://plutojl.org/) notebooks to generate the figures.

This repository contains a legacy copy of [this repository](https://github.com/adigioacchino/MaxEntNucleotideBiases.jl) that contains a Julia package introduced with the paper and is needed to reproduce its results.

## Preliminaries
First of all, you need to retrieve [this dataset](https://zenodo.org/doi/10.5281/zenodo.10050076) from Zenodo, uncompress it, and place it in a directory called `data` (from the root of the repository, `data/simplehost_selectedhostsfamilies_FluPB2_flubefore2009.csv.gz` must be a valid file).
    
Then, you need to install [Julia](https://julialang.org/) and [Snakemake](https://snakemake.github.io/), following the instructions on their respective websites.

## Reproducing the results
Results can be reproduced by running the following steps:
- Step 1: instantiate Julia's environment that is present in `computations/workflow/envs` with `julia --project=. -e 'using Pkg; Pkg.instantiate()'` run from the `computations/workflow/envs` directory (this will install all the necessary Julia packages);
- Step 2: run the `infer_all_hosts` rule in the Snakefile with `snakemake -cX infer_all_hosts` (X is the number of cores to use);
- Step 3: run the `train_VIDHOP_all` rule with `snakemake -cX --use-conda train_VIDHOP_all` (X is the number of cores to use);
- Step 4 (optional): run the `clean_VIDHOP_trainmodel` to remove the unnecessary files;
- Step 5: activate and instantiate the environment in `computations/workflow/notebooks` and run `using Pluto; Pluto.run()` to open the notebooks and run them to obtain the figures.