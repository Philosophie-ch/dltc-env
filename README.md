# Dialectica Compilation Environment

This project contains utils to spin up a docker container with all of the tools needed to compile Dialectica articles.
The main interface is the `dltc-env` terminal command that gets installed in your system when you run the installation script.


## Setup

### Requirements

This project requires the following software to be installed on your machine:

- [Docker](https://docs.docker.com/get-docker/)
- The team's shared workhouse folder present in your system


### Installation

To install the `dltc-env` command in your terminal, two methods are provided. If one does not work (e.g., `curl` or `wget` are not installed or not available), try the other one:

- With `wget`:
```bash
wget -O - https://raw.githubusercontent.com/Philosophie-ch/dltc-env/simplify-use/install.sh | bash
```

- With `curl`:
```bash
curl -sSL https://raw.githubusercontent.com/Philosophie-ch/dltc-env/simplify-use/install.sh | bash
```


## Use

The container should be automatically started after installation, but if you want to be sure, just start a new terminal and run the following command from anywhere:
```bash
dtlc-env start
```

To see the available commands, run:
```bash
dltc-env --help
```

### Stopping and restarting the container

Once you are done working, you can stop the container with the following command (from anywhere):
```bash
dltc-env stop
```

Remember to start the container again before you start working (from anywhere):
```bash
dltc-env start
```

### Updating the container

Whenever a new version of the project is annouced, just run:
```bash
dltc-env update
```


## Development

Pull requests are welcome.
For major changes, please open an issue first to discuss what you would like to change.

### Docker images

The docker images that this project uses are built from the following repository:

- [dltc-env-dockerfiles](https://github.com/Philosophie-ch/dltc-env-dockerfiles)

### Structure

The project works as follows:

- `install.sh`: bootstraps a basic folder structure, with the root at `${HOME}/.dltc-env`, downloads `bin/dltc-env`, `aux/dltc-env-setup.sh`, and executes the setup script.

- `aux/dltc-env-setup.sh`: sets up the environment and runs the docker container. It will:
  + Automatically download the files of the project and generate the full folder structure
  + Call many auxiliary functions from `aux/dltc-env-utils.sh`
  + Automatically generate an environment file at `docker/.env`, a process that includes finding a unique hash present in the team's shared folder to extract some information from it
  + Note that it will repristine the `${HOME}/.dltc-env` folder and force remove and recreate the `dltc-env` container (if running) everytime it's executed
  + If successful, it creates the file `.dltc_setup_flag` to mark that the setup happened successfully at least once in the machine

- `bin/dltc-env`: after installation, this provides a CLI for the functionalities: `start`, `stop`, `setup`, `update`.
  + `setup` and `update` will execute the `aux/dltc-env-setup.sh` script again
  + `start` and `stop` will execute the corresponding functions from `aux/dltc-env-utils.sh`
  + The `bin` folder is added to the `PATH` by the setup script, so the `dltc-env` command can be called from anywhere

- The other files are downloaded and/or generated automatically, and are managed by the scripts above:
    + The `logs` folder will contain logs of the scripts of this project; only the latest log is kept for each script
    + The `docker` folder will contain the `.env` file and the `docker-compose.yml` file, which are used to start the container
    + The `aux/dltc-env-utils.sh` file contains several auxiliary functions that are called by the other scripts, so most important changes will most likely happen here


### Idea

The idea is to have a simple and easy to use environment for compiling Dialectica articles.

The user should not have to worry about the details, and should be able to start working with a single command.
The environment should be as isolated as possible from the host system, and should be easy to update and maintain, which is why we use Docker.
Updates should be as simple as possible, get the latest changes for this project and the docker images, and should not require the user to do anything other than running a command.

Finally, setup and dependencies should be as minimal as possible, and the user should not have to worry about them. This is why we use a single installation script that downloads everything and automatically sets up the environment.
