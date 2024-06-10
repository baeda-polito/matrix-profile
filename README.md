# Matrix Profile Paper

The Matrix Profile has the potential to revolutionize time series data mining because of its generality, versatility,
simplicity and scalability. In particular it has implications for time series motif discovery, time series joins,
shapelet discovery (classification), density estimation, semantic segmentation, visualization, rule discovery,
clustering etc.

![](/Paper/images/Fig%201%20-%20MP%20and%20CMP%20explained%403.png)

## Project Organization

- `src`: Folder containing the contextual matrix profile codebase (i.e., folder `cmp`) and necessary packages (i.e., `distancematrix`).
- `tests`: Contains Python-based test cases to validate source code.
- `pyproject.toml`: Contains metadata about the project and configurations for additional tools used to format, lint,
  type-check, and analyze Python code. (
  See [here](https://packaging.python.org/en/latest/guides/writing-pyproject-toml/) for reference)

## Getting started

Create virtual environment and activate it and install dependencies:

- Makefile
  ```bash
  make setup
  ```
- Linux:
  ```bash
  python3 -m venv .venv
  source .venv/bin/activate
  pip install -r requirements.txt
  ```
- Windows:
  ```bash
  python -m venv venv
  venv\Scripts\activate
  pip install -r requirements.txt
  ```

Run the main script through the console:
```bash
source .venv/bin/activate
python -m src.cmp.main
```

You should see in the terminal a message output like the following:

```txt
CONTEXT 1 : Subsequences of 05:45 h (m = 23) that start in [00:00,01:00) (ctx_from00_00_to01_00_m05_45)
99.997%        0.0 sec

- Cluster 1 (1.181 s)   -> 1 anomalies
- Cluster 2 (0.508 s)   -> 3 anomalies
- Cluster 3 (0.473 s)   -> 4 anomalies
- Cluster 4 (0.658 s)   -> 5 anomalies
- Cluster 5 (-)         -> no anomalies green
```

At the end of the execution you can find the results in the [`results`](src/cmp/results) folder.


## Run using docker

Build the docker image.
- Makefile
  ```bash
  make docker-build
  ```
- Linux:
  ```bash
  docker build -t cmp .
  ```

Run the docker image.
- Makefile
  ```bash
  make docker-run
  ```
- Linux:
  ```bash
  docker run cmp
  ```

At the end of the execution you can find the results in the [`results`](src/cmp/results) folder.

### Context definition

```
# 2) User Defined Context
# We want to find all the subsequences that start from 00:00 to 02:00 (2 hours) and covers the whole day
# In order to avoid overlapping we define the window length as the whole day of
# observation minus the context length.

# - Beginning of the context 00:00 AM [hours]
context_start = 17

# - End of the context 02:00 AM [hours]
context_end = 19

# - Context time window length 2 [hours]
m_context = context_end - context_start  # 2

# - Time window length [observations]
# m = 96 [observations] - 4 [observation/hour] * 2 [hours] = 88 [observations] = 22 [hours]
# m = obs_per_day - obs_per_hour * m_context
m = 20  # with guess

# Context Definition:
# example FROM 00:00 to 02:00
# - m_context = 2 [hours]
# - obs_per_hour = 4 [observations/hour]
# - context_start = 0 [hours]
# - context_end = context_start + m_context = 0 [hours] + 2 [hours] = 2 [hours]
contexts = GeneralStaticManager([
    range(
        # FROM  [observations]  = x * 96 [observations] + 0 [hour] * 4 [observation/hour]
        (x * obs_per_day) + context_start * obs_per_hour,
        # TO    [observations]  = x * 96 [observations] + (0 [hour] + 2 [hour]) * 4 [observation/hour]
        (x * obs_per_day) + (context_start + m_context) * obs_per_hour)
    for x in range(len(data) // obs_per_day)
])
```

## Cite

```latex
@article{CHIOSA2022112302,
title = {Towards a self-tuned data analytics-based process for an automatic context-aware detection and diagnosis of anomalies in building energy consumption timeseries},
journal = {Energy and Buildings},
volume = {270},
pages = {112302},
year = {2022},
issn = {0378-7788},
doi = {https://doi.org/10.1016/j.enbuild.2022.112302},
url = {https://www.sciencedirect.com/science/article/pii/S037877882200473X},
author = {Roberto Chiosa and Marco Savino Piscitelli and Cheng Fan and Alfonso Capozzoli},
keywords = {Building energy consumption, Anomaly detection and diagnosis, Contextual matrix profile, Timeseries analytics},
abstract = {Recently, the spread of IoT technologies has led to an unprecedented acquisition of energy-related data providing accessible knowledge on the actual performance of buildings during their operation. A proper analysis of such data supports energy and facility managers in spotting valuable energy saving opportunities. In this context, anomaly detection and diagnosis (ADD) tools allow a prompt and automatic recognition of abnormal and non-optimal energy performance patterns enabling a better decision-making to reduce energy wastes and system inefficiencies. To this aim, this paper introduces a novel meter-level ADD process capable to identify energy consumption anomalies at meter-level and perform diagnosis by exploiting information at sub-load level. The process leverages supervised and unsupervised analytics techniques coupled with the distance-based contextual matrix profile (CMP) algorithm to discover infrequent subsequences in energy consumption timeseries considering specific boundary conditions. The proposed process has self-tuning capabilities and can rank anomalies at both meter and sub-load level by means of robust severity score. The methodology is tested on one-year energy consumption timeseries of a medium/low voltage transformation cabin of the university campus of Politecnico di Torino leading to the detection of 55 anomalous subsequences that are diagnosed by analysing a group of 8 different sub-loads.}
}
```

## Contributors

- [Roberto Chiosa]()

## License

## Aknowledgements

