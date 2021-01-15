# WITCH : World Induced Technical Change Hybrid model

Version 5.2.0

This is the WITCH integrated assessment model (https://www.witchmodel.org) designed to assess climate change impacts and solutions. WITCH is a global dynamic model integrating the interactions between the economy, the technological options, and climate change. The WITCH model represents the complete dynamic of climate change mitigation and adaptation for 17 macro-regions for the next 100 years. 

## Quick setup

### From the bundle

1) Download and unzip https://github.com/witch-team/witchmodel/releases/download/v5.2.0/witchmodel-bundle.zip

2) Run WITCH (you will need a working `GAMS/CONOPT` license).

```sh
gams run_witch.gms
```

### From the source code

1) Get the source code of the WITCH model

```Shell
git clone git@github.com:witch-team/witchmodel.git
```

2) Download and unzip https://github.com/witch-team/witchmodel/releases/download/v5.2.0/witchmodel-bundle.zip

3) Copy the entire directory `data_witch17` into the WITCH directory (`witchmodel`).

3) Run WITCH (you will need a working GAMS/CONOPT license).

```sh
cd witchmodel
gams run_witch.gms
```

## Documentation

An extensive documentation of the WITCH model is available at https://www.witchmodel.org/documentation.

## Contact information

info@witchmodel.org