# --- Global Variables ---
PULUMI_STACK := echo ${GITHUB_REPOSITORY} | awk -F '[/]' '{print $2}'
GITHUB_REPOSITORY_STRING := $(shell echo ${GITHUB_REPOSITORY} | tr '[:upper:]' '[:lower:]')
KONDUCTOR_NAME ?= $(if ${GITHUB_REPOSITORY_STRING},${GITHUB_REPOSITORY_STRING},pulumi/devcontainer)
DOCKER_IMAGE_NAME := "ghcr.io/${KONDUCTOR_NAME}:latest"

# --- Help ---
# This section provides a default help message displaying all available commands
help:
	@echo "Available commands:"
	@echo "  login                Log in to Pulumi"
	@echo "  esc-env              Run a Pulumi ESC environment"
	@echo "  up                   Deploy Pulumi infrastructure"
	@echo "  kind                 Deploy a local kubernetes cluster using Kind Kubernetes-in-Docker"
	@echo "  act                  Test GitHub Actions locally"
	@echo "  devcontainer         Update the .github/devcontainer submodule"
	@echo "  test                 Run all tests"

# --- Pulumi Commands ---
# Log in to Pulumi
login:
	@echo "Logging in to Pulumi..."
	direnv allow
	pulumi login
	@echo "Login successful."

# Run a Pulumi ESC environment
esc-env:
	@echo "Running Pulumi ESC environment..."
	# Replace the below command with the actual command to run the Pulumi ESC environment
	pulumi esc env open --stack $(PULUMI_STACK)
	@echo "Pulumi ESC environment running."

# Deploy Pulumi infrastructure
up:
	@echo "Deploying Pulumi infrastructure..."
	clear
	pulumi up --stack $(PULUMI_STACK)
	@echo "Deployment complete."

# --- Kind ---
# Kind Create Cluster
kind:
	@echo "Creating Kind Cluster..."
	direnv allow
	kind create cluster
	kind get kubeconfig > $KUBECONFIG
	kubectl get po -A
	@echo "Kind Cluster Created."

# --- GitHub Actions ---
# Install & Run the GitHub 'gh-act' extension for local testing of GitHub Actions
act:
	@echo "Test Github Workflows."
	clear
	act -s GITHUB_TOKEN=${GITHUB_TOKEN} -s ACTIONS_RUNTIME_TOKEN=${GITHUB_TOKEN} -s GHA_GITHUB_TOKEN=${GITHUB_TOKEN}
	@echo "Github Workflow Complete."

# --- Docker Build ---
# Build the Docker image
build:
	@echo "Building Docker image..."
	clear
	docker build --progress plain --pull --build-arg GITHUB_TOKEN="${GITHUB_TOKEN}" --tag ${DOCKER_IMAGE_NAME} -f ./docker/Dockerfile ./docker
	@echo "Docker image built."

# --- Docker Build & Push ---
# Build the Docker image
build-push:
	@echo "Building Docker image & pushing to ${DOCKER_IMAGE_NAME}..."
	clear
	docker build --progress plain --push --pull --tag ${DOCKER_IMAGE_NAME} -f ./docker/Dockerfile ./docker
	@echo "Docker published to ${DOCKER_IMAGE_NAME}..."

# --- Default Command ---
devcontainer::
	git submodule update --init --recursive .github/devcontainer
	git submodule update --remote --merge .github/devcontainer
	rsync -av .github/devcontainer/devcontainer/* .devcontainer

# --- Testing ---
# Add your testing scripts here
test:
	@echo "Running tests..."
	# Add commands to run your tests
	@echo "Testing complete."

# --- Default Command ---
# Default command when running 'make' without arguments
all: help
