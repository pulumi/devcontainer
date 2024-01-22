# --- Global Variables ---
PULUMI_STACK := echo ${GITHUB_REPOSITORY} | awk -F '[/]' '{print $2}'
GITHUB_REPOSITORY_STRING := $(shell echo ${GITHUB_REPOSITORY} | tr '[:upper:]' '[:lower:]')
KONDUCTOR_NAME ?= $(if ${GITHUB_REPOSITORY_STRING},${GITHUB_REPOSITORY_STRING},pulumi/devcontainer)
DOCKER_IMAGE_NAME := "ghcr.io/${KONDUCTOR_NAME}:latest"

# --- Help ---
# This section provides a default help message displaying all available commands
help:
	@echo "Available commands:"
	@echo "  devcontainer-update  Update the .github/devcontainer submodule"
	@echo "  pulumi-login         Log in to Pulumi"
	@echo "  esc-run              Run a Pulumi ESC environment"
	@echo "  pulumi-up            Deploy Pulumi infrastructure"
	@echo "  act                  Install the GitHub 'gh-act' extension"
	@echo "  test                 Run all tests"

# --- Docker Build ---
# Build the Docker image
docker-build:
	@echo "Building Docker image..."
	clear
	docker build --progress plain --pull --build-arg GITHUB_TOKEN="${GITHUB_TOKEN}" --tag ${DOCKER_IMAGE_NAME} -f ./docker/Dockerfile ./docker
	@echo "Docker image built."

# --- Docker Build & Push ---
# Build the Docker image
docker-build-push:
	@echo "Building Docker image & pushing to ${DOCKER_IMAGE_NAME}..."
	clear
	docker build --progress plain --push --pull --tag ${DOCKER_IMAGE_NAME} -f ./docker/Dockerfile ./docker
	@echo "Docker published to ${DOCKER_IMAGE_NAME}..."

# --- GitHub Actions ---
# Install & Run the GitHub 'gh-act' extension for local testing of GitHub Actions
act:
	@echo "Test Github Workflows."
	gh act -s GITHUB_TOKEN=${GITHUB_TOKEN} -s ACTIONS_RUNTIME_TOKEN=${GITHUB_TOKEN} -s GHA_GITHUB_TOKEN=${GITHUB_TOKEN}
	@echo "Github Workflow Complete."

# --- Pulumi Commands ---
# Log in to Pulumi
pulumi-login:
	@echo "Logging in to Pulumi..."
	pulumi login
	@echo "Login successful."

# Deploy Pulumi infrastructure
pulumi-up:
	@echo "Deploying Pulumi infrastructure..."
	pulumi up --stack $(PULUMI_STACK)
	@echo "Deployment complete."

# Run a Pulumi ESC environment
pulumi-esc-env:
	@echo "Running Pulumi ESC environment..."
	# Replace the below command with the actual command to run the Pulumi ESC environment
	pulumi esc env open --stack $(PULUMI_STACK)
	@echo "Pulumi ESC environment running."

# --- Devcontainer Management ---
# Update the .github/devcontainer submodule
update-devcontainer:
	@echo "Updating .github/devcontainer submodule..."
	git submodule update --init --recursive .github/devcontainer
	@echo "Update complete."

# --- Testing ---
# Add your testing scripts here
test:
	@echo "Running tests..."
	# Add commands to run your tests
	@echo "Testing complete."

# --- Kind ---
# Kind Create Cluster
kind:
	@echo "Creating Kind Cluster..."
	mkdir .kube
	docker volume create cilium-worker-n01
	docker volume create cilium-worker-n02
	docker volume create cilium-control-plane-n01
	kind create cluster --config hack/kind.yaml
	@echo "Kind Cluster Created."

# --- Default Command ---
devcontainer::
	git submodule update --init --recursive .github/devcontainer
	git submodule update --remote --merge .github/devcontainer
	rsync -av .github/devcontainer/devcontainer/* .devcontainer

# --- Default Command ---
# Default command when running 'make' without arguments
all: help
