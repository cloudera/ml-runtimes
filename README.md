# Cloudera Machine Learning Runtimes
Cloudera ML Runtimes are a set of Docker images created to enable machine learning development and host data applications in the [Cloudera Data Platform (CDP)](https://www.cloudera.com/products/cloudera-data-platform.html) and the [Cloudera Machine Learning (CML)](https://www.cloudera.com/products/machine-learning.html) service.

ML Runtimes provide a flexible, fully customizable, lightweight development and production machine learning environment for both CPU and GPU processing frameworks while enabling unfettered access to data, on-demand resources, and the ability to install and use any libraries/algorithms without IT assistance.

To read more, visit our [documentation](https://docs.cloudera.com/machine-learning/cloud/runtimes/topics/ml-runtimes-overview.html).

## PBJ Runtimes
Powered by Jupyter (PBJ) Runtimes are the second generation of ML Runtimes. While the original ML Runtimes relied on a custom proprietary integration with CML, PBJ Runtimes rely on Jupyter protocols for ecosystem compatibility and openness.

## Open source
For data scientists who need to fully understand the environment they are working in, Cloudera provides the Dockerfiles and all dependencies in this repository that enables the construction of the official Cloudera ML Runtime images.

The open sources PBJ Runtime Dockerfiles serve as a blueprint to create custom ML Runtimes so data scientists or partners can build ML Runtime images on their selected OS (base image), with the kernel of their choice, or just integrate their existing ML container images with Cloudera Machine Learning.

To rebuild and register these ML Runtimes in a CML environment the Edition Runtime metadata needs to be changed as it's reserved for the official Cloudera Runtimes. To learn more, follow the PBJ Workbench [documentation](https://docs.cloudera.com/machine-learning/cloud/runtimes/topics/ml-pbj-workbench-requirements.html)

