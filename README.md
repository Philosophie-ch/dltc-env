# Dialectica Compilation Environment

This repository contains utils to spin up a docker container with all of the tools needed to compile Dialectica articles.


## Setup

### Requirements

- [Docker](https://docs.docker.com/get-docker/)


### Installation

1. Clone this repository in your local machine and enter the directory:
```bash
mkdir ~/gitrepos  # suggested, but any directory will do
cd ~/gitrepos
git clone
cd dltc-env
```

2. Copy the `.env.template` file to `.env` and fill in the variables:
```bash
cp .env.template .env
# edit .env with your preferred tex editor
```

- 2.1 `ARCH`: the architecture of your machine. If you are on a Mac with an Apple Silicon chip, set this to "arm64". Otherwise, set it to "amd64" (for Macs with Intel chips, Windows, and Linux)
- 2.2 `DLTC_WORKHOUSE_DIRECTORY`: the full path, on your local machine, to the 'dltc-workhouse' shared folder inside Dropbox
- 2.3 `DOCKERHUB_TOKEN`: the login token for the dockerhub account. You can find it in the "Institutional set-up" page in our Google Drive
- 2.4 `DOCKERHUB_USERNAME`: the dockerhub username of the association. Leave it as "philosophiech"


## Usage

Once set up, just run the following command from the root of the repository:
```bash
# On Linux and Mac
./dltc-env-start.sh
```

```powershell
# On Windows
# Note that you might need to change the execution policy
.\dltc-env-start.ps1
```

This will start a docker container with all of the tools needed to compile Dialectica articles.
The latest version will be pulled automatically from dockerhub.


### Stopping and restarting the container

Once you are done working, you can stop the container with the following command (from anywhere):
```bash
docker stop dltc-env
```

Remember to start the container again before you start working (from anywhere):
```bash
docker start dltc-env
```

### Updating the container

Whenever a new version of the container is annouced, go back to the root of the repository and run again:
```bash
# On Linux and Mac
./dltc-env-start.sh
```

```powershell
# On Windows
.\dltc-env-start.ps1
```