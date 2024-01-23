# --- Global Variables ---
GITHUB_REPOSITORY_STRING := $(shell echo ${GITHUB_REPOSITORY} | tr '[:upper:]' '[:lower:]')
DEVCONTAINER_NAME ?= $(if ${GITHUB_REPOSITORY_STRING},${GITHUB_REPOSITORY_STRING},pulumi/devcontainer)
PULUMI_STACK := echo ${GITHUB_REPOSITORY} | awk -F '[/]' '{print $2}'
DOCKER_IMAGE_NAME := "ghcr.io/${DEVCONTAINER_NAME}:latest"

# --- Help ---
# Provides a default help message displaying all available commands
help:
	@echo "Available commands:"
	@echo "  help                 Display this help message."
	@echo "  login                Authenticate with cloud services."
	@echo "  esc                  Run a Pulumi ESC environment with an optional argument. Default is 'kubernetes'."
	@echo "  up                   Deploy Pulumi IaC program using the stack name 'codespace'."
	@echo "  down                 Destroy Pulumi infrastructure."
	@echo "  kind                 Deploy a local Kubernetes cluster using Kind (Kubernetes-in-Docker)."
	@echo "  clean                Destroy Pulumi resources, tear down the Kind cluster, and clean up configurations."
	@echo "  clean-all            Perform all actions in 'clean', plus remove Docker volumes."
	@echo "  test                 Run a series of commands to test the setup (kind, up, clean, clean-all)."
	@echo "  act                  Test GitHub Actions locally with the 'gh-act' extension."
	@echo "  devcontainer         Update the .github/devcontainer submodule and sync files."

# --- Pulumi Login Command ---
login:
	@echo "Logging in to Pulumi..."
	direnv allow
	pulumi login
	@echo "Login successful."

# --- Pulumi ESC ---
# Accepts one argument for Pulumi ESC environment; default is 'kubernetes'
# Usage:
#  - make esc ENV=dev
#  - make esc ENV=test
#  - make esc ENV=prod
esc: login
	$(eval ENV := $(or $(ENV),kubernetes))
	@echo "Running Pulumi ESC environment with argument ${ENV}..."
	@env esc open --format shell ${ENV}
	@echo "Pulumi ESC environment running."

# Deploy Pulumi infrastructure
up:
	@echo "Deploying Pulumi infrastructure..."
	pulumi stack select codespace || pulumi stack init codespace && pulumi stack select codespace
	pulumi install
	pulumi up --stack codespace --yes --skip-preview
	sleep 10
	kubectl get po -A
	@echo "Deployment complete."

# Destroy Pulumi infrastructure
down:
	@echo "Destroying Pulumi infrastructure..."
	pulumi down --stack codespace --yes --skip-preview
	@echo "Infrastructure teardown complete."

# --- Kind ---
kind:
	@echo "Creating Kind Cluster..."
	direnv allow
	docker volume create cilium-worker-n01
	docker volume create cilium-worker-n02
	docker volume create cilium-control-plane-n01
	kind create cluster --config hack/kind.yaml
	kind get kubeconfig --name cilium | tee .kube/config >/dev/null
	sleep 5
	kubectl get po -A
	@echo "Kind Cluster Created."

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

# --- Cleanup ---
clean: down
	@echo "Cleaning up..."
	kind delete cluster --name cilium || true
	rm -rf .kube/config || true
	@echo "Cleanup complete."

clean-all: clean
	docker volume rm cilium-worker-n01 || true
	docker volume rm cilium-worker-n02 || true
	docker volume rm cilium-control-plane-n01 || true
	@echo "Extended cleanup complete."

# --- GitHub Actions ---
act:
	@echo "Testing GitHub Workflows locally."
	act -s GITHUB_TOKEN=${GITHUB_TOKEN} -s ACTIONS_RUNTIME_TOKEN=${GITHUB_TOKEN} -s GHA_GITHUB_TOKEN=${GITHUB_TOKEN}
	@echo "GitHub Workflow Test Complete."

# --- Maintain Devcontainer ---
devcontainer:
	git submodule update --init --recursive .github/devcontainer
	git submodule update --remote --merge .github/devcontainer
	rsync -av .github/devcontainer/devcontainer/* .devcontainer

# --- Testing ---
test: kind up clean clean-all

# --- Default Command ---
all: help
