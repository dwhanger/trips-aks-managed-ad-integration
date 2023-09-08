# Openhack - Containers 2.0 

<!-- 
Guidelines on README format: https://review.docs.microsoft.com/help/onboard/admin/samples/concepts/readme-template?branch=master

Guidance on onboarding samples to docs.microsoft.com/samples: https://review.docs.microsoft.com/help/onboard/admin/samples/process/onboarding?branch=master

Taxonomies for products and languages: https://review.docs.microsoft.com/new-hope/information-architecture/metadata/taxonomies?branch=master
-->

## Tyee Software

This project was originally presented during an OpenHack on Containers in Seattle.  In the mean time,
these containers have been extended to turn the manual steps into actionable Terraform IaC that can 
be used as a basis for future Kubernetes applications as we move forward.  Right now, the Terraform 
files are located in the tf sub-directory and working files are put into the _work directory.  When
you run the Terraform, you need to specify the tfvars file you want to feed into it to create your stack.
These Terraform files are aligned for usage in Nirvana so they create their own vnet, subnets, nsgs, etc
and everything else.  You will need to map out your own vnet networking address range but it is recommended 
that you keep the addresses proportional to what you see listed in the devintus.tfvars file so that the AKS
cluster will spin up correctly.

This Terraform makes use of separate directory for housing RBAC rights for the pod level authentication.  Some
additional configuration, as in adding of a user to this new tenant, is expected.


## Contents

This repo houses the source code and dockerfiles for the Containers OpenHack event.

The application used for this event is a heavily modified and recreated version of the original [My Driving application](https://github.com/Azure-Samples/MyDriving).

| File/folder       | Description                                |
|-------------------|--------------------------------------------|
| `dockerfiles`     | Dockerfiles for source code                |
| `src`             | Sample source code for POI, Trips, User (Java), UserProfile (Node.JS), and TripViewer                     |
| `.gitignore`      | Define what to ignore at commit time.      |
| `CODE_OF_CONDUCT.md` | Code of conduct.                        |
| `LICENSE`         | The license for the sample.                |

## DockerFile Mapping

| DockerFile       | Description                                |
|-------------------|-----------------------|
| Dockerfile_0      | src/user-java         |
| Dockerfile_1      | src/tripviewer        |
| Dockerfile_2      | src/userprofile       |
| Dockerfile_3      | src/poi               |
| Dockerfile_4      | src/trips             |

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
