# Create a GKE Cluster with Windows Node Pool 

## Create the GKE cluster

Create a GKE cluster with a Windows Server node pool.

```cmd
export CLUSTER_NAME=your_cluster_name_here

gcloud container clusters create $CLUSTER_NAME \
    --enable-ip-alias \
    --num-nodes=1 \
    --release-channel regular

gcloud container node-pools create windows-ltsc-pool \
    --cluster=$CLUSTER_NAME \
    --image-type=WINDOWS_LTSC \
    --no-enable-autoupgrade \
    --machine-type=n1-standard-2

gcloud container clusters get-credentials $CLUSTER_NAME
```

Refer to [creating a cluster using Windows Server node pools](https://cloud.google.com/kubernetes-engine/docs/how-to/creating-a-cluster-windows) for more information about Windows Server node pools in GKE.

### Enabling Google APIs

If you have not already done so, make sure to enable the following APIs in your project.  You can do this with the following command, easiest if done in the Google Cloud shell:

```bash
gcloud services enable containerregistry.googleapis.com run.googleapis.com compute.googleapis.com cloudbuild.googleapis.com
```

## Get the code

NOTE: This code relies on running from the `gkewindows` branch.  In order to walk through these steps, open this up in a browser to follow along and then use these steps:

```cmd
# Clone the repository
git clone https://github.com/jjdelorme/contosouniversity

# Checkout the 'gkewindows' branch, which is the original (unconverted) .NET Framework 4.5 application.
git checkout gkewindows
```

## Connection Strings
Note that the database connection string is stored as a K8S secret.  To reference this secret with no code changes, use the following ```configSource``` in the Web.config file.  Notice the path is relative to the deployment, a subdirectory in the deployment path.

```xml
<configuration>
  ...
  <connectionStrings configSource="secret\connectionStrings.config"/>
  ...
</configuration>
```

The secret is created as such from a file that contains just the connectionStrings section.  Create a file named `connectionstrings.config`:

```xml
<connectionStrings>
    <add name="SchoolContext"
         connectionString="Data Source=SERVER-NAME;User=MYUSER;Password=MYPASSWORD;Initial Catalog=ContosoUniversity;"
        providerName="System.Data.SqlClient" />
</connectionStrings>
```

Now create the secret from this file using the following command:

```bash
kubectl create secret generic connection-strings --from-file=connectionStrings.config
```

The deployment in `deploy.yaml` references this with the mount path, a fully qualified subdirectory of the deployment (relative to C:\).  Specifying a root directory like /secret for example is at risk of IIS not having permissions to read and will throw a 500 error.  Additionally specifying the actual path of deployment (not a subdirectory) will cause it to overwrite the whole deployment directory.

```yaml
        volumeMounts: 
        - name: connection-strings
          mountPath: "/inetpub/wwwroot/secret"
          readOnly: true        
...
      volumes:
      - name: connection-strings
        secret:
          secretName: connection-strings
```

## Create the Windows Container Dockerfile
The application is written in .NET Framework 4.5, but will run in a .NET Framework 4.8 runtime environment as depicted below.  The `Dockerfile` should live in the solution directory.

```dockerfile
# escape=`

FROM mcr.microsoft.com/dotnet/framework/sdk:4.8-windowsservercore-ltsc2019 AS build
WORKDIR /source
COPY . /source

RUN msbuild ContosoUniversity.sln /t:restore /p:RestorePackagesConfig=true
RUN msbuild /p:Configuration=Release `
	/t:WebPublish `
	/p:WebPublishMethod=FileSystem `
	/p:publishUrl=C:\deploy

FROM mcr.microsoft.com/dotnet/framework/aspnet:4.8 AS runtime
COPY --from=build /deploy /inetpub/wwwroot

EXPOSE 80
```
### Run container locally (OPTIONAL)

You can skip this step and send the build directly to [Use Cloud Build](#Use-Cloud-Build-for-Windows-Containers) if you like.  However, if you have Docker installed locally and want to test the container, follow these steps.

Build the container by running these commands from the solution directory.
```cmd
# Store the Project env variable
gcloud info --format=value(config.project) > __project && set /p PROJECT= < __project && del __project

# Build the container
docker build -t gcr.io/%PROJECT%/contosouniversity-windows:v1_ltsc2019 -f Dockerfile .

# Run the container
docker run -it --rm -p 8080:80 --name iis gcr.io/%PROJECT%/contosouniversity-windows:v1_ltsc2019
```
You should now be able to launch a browser with [http://localhost:8080](http://localhost:8080) to see the application.

### Manually push the container to your Google Container Registry

Again, this step can be skipped if you're going to [Use Cloud Build](#Use-Cloud-Build-for-Windows-Containers).

## Use Cloud Build for Windows Containers

1. Ensure that you have authenticated against the registry.
```cmd
gcloud auth configure-docker
```

1. Push the container to the registry.
```cmd
docker push gcr.io/%PROJECT%/contosouniversity-windows:v1_ltsc2019
```

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
  - 'gcr.io/$PROJECT_ID/contosouniversity-windows:v1-ltsc2019'
```

Now use Cloud Build to build and push the Windows Container.

  ```cmd
  gcloud builds submit
  ```

## Deploy to GKE

This is probably easiest done from the Google Cloud Shell.  If you did the earlier steps in cloud shell, the PROJECT env variable will already be set.  

```bash
export PROJECT=$(gcloud info --format='value(config.project)')
export CLUSTER_NAME=your_cluster_name_here

# Make sure you have authenticated against the GKE cluster locally:
gcloud container clusters get-credentials $CLUSTER_NAME

envsubst < deploy.yaml | kubectl apply -f -
```
The above script uses the `envsubst` tool to substitute `${PROJECT}` with your project which is obtained in the first line.  The output of that script is applied to your GKE cluster.  You can see the relevant placeholder in the `deploy.yaml` file below:

```yaml
      containers:
      - image: gcr.io/${PROJECT}/contosouniversity-windows:v1-ltsc2019
```
