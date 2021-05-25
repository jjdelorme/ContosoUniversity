# Create a GKE Cluster with Windows Node Pool 

## Create the GKE cluster

Following these [instructions](https://cloud.google.com/kubernetes-engine/docs/how-to/creating-a-cluster-windows), note that you must create the cluster from gcloud rather than the console UI because the `--enable-ip-alias` is not available there.

```cmd
gcloud container clusters create jasondel-standard \
    --enable-ip-alias \
    --num-nodes=1 \
    --release-channel regular

gcloud container node-pools create windows-ltsc-pool \
    --cluster=jasondel-standard \
    --image-type=WINDOWS_LTSC \
    --no-enable-autoupgrade \
    --machine-type=n1-standard-2

gcloud container clusters get-credentials jasondel-standard    
```

## Create the Windows Container Dockerfile
```dockerfile
# escape=`

FROM mcr.microsoft.com/dotnet/framework/sdk:4.7.2-windowsservercore-ltsc2019 AS build
WORKDIR /source
COPY . /source

RUN msbuild -t:restore -p:RestorePackagesConfig=true
RUN msbuild /p:Configuration=Release `
	/t:WebPublish `
	/p:WebPublishMethod=FileSystem `
	/p:publishUrl=C:\Deploy

FROM mcr.microsoft.com/dotnet/framework/aspnet:4.7.2 AS runtime
COPY --from=build /deploy /inetpub/wwwroot

EXPOSE 80
```

## Use Cloud Build for Windows Containers

### Preparing the environment

It's easiest to do this from the [Google Cloud Shell](https://shell.cloud.google.com)

```cmd
gcloud services enable compute.googleapis.com

export PROJECT=$(gcloud info --format='value(config.project)')
export MEMBER=$(gcloud projects describe $PROJECT --format 'value(projectNumber)')@cloudbuild.gserviceaccount.com

gcloud projects add-iam-policy-binding $PROJECT --member=serviceAccount:$MEMBER --role='roles/compute.instanceAdmin'
gcloud projects add-iam-policy-binding $PROJECT --member=serviceAccount:$MEMBER --role='roles/iam.serviceAccountUser'
gcloud projects add-iam-policy-binding $PROJECT --member=serviceAccount:$MEMBER --role='roles/compute.networkViewer'
gcloud projects add-iam-policy-binding $PROJECT --member=serviceAccount:$MEMBER --role='roles/storage.admin'

gcloud compute firewall-rules create allow-winrm-ingress --allow=tcp:5986 --direction=INGRESS
```

The `gke-windows-builder` is not specific to **GKE**, but it was built by the GKE Windows engineering team, so don't be thrown off by the name.  It doesn't actually use or depend on GKE.  By default the `gke-windows-builder` [supports building](https://cloud.google.com/kubernetes-engine/docs/tutorials/building-windows-multi-arch-images) mult-arch Windows Container images which builds a version for each supported architecture.  In the example below, we can specify only a single version `ltsc2019` in our case.

```yaml
timeout: 3600s
steps:
- name: 'gcr.io/gke-release/gke-windows-builder:release-2.5.0-gke.0'
  args:
  - --versions
  - 'ltsc2019'
  - --container-image-name
  - 'gcr.io/$PROJECT_ID/contosouniversity:v1-ltsc2019'
  ```

Now use Cloud Build to build and push the Windows Container.

  ```cmd
  gcloud builds submit
  ```