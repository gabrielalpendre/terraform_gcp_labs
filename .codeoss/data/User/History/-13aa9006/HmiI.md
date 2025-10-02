# Google Cloud Terraform Lab Automation Script

This script automates the steps for the Google Cloud Terraform Lab (GSP345). It sets up a Terraform environment, imports existing infrastructure, makes several changes, and configures networking components.

## Prerequisites

- A Google Cloud project.
- The `gcloud` CLI installed and authenticated.
- `terraform` installed.
- Two existing VM instances in the project.

## How to Run

1.  Make the script executable:
    ```bash
    chmod +x abhishek.sh
    ```

2.  Run the script:
    ```bash
    ./abhishek.sh
    ```

3.  When prompted, enter the following details:
    -   **Bucket Name**: A unique name for a new GCS bucket.
    -   **Instance Name**: A name for a new VM instance to be created.
    -   **VPC Name**: A name for a new VPC network.
    -   **Zone**: The GCP zone for the resources (e.g., `us-central1-a`).

The script will then execute all the lab steps automatically.

## Script Breakdown

The script is divided into several stages, each performing a specific set of Terraform operations.

### 1. Initial Setup and User Input

- The script starts by defining color-coded output for better readability.
- It displays a welcome message.
- It prompts the user for required variables (`BUCKET`, `INSTANCE`, `VPC`, `ZONE`).
- It configures the `gcloud` CLI with the specified zone and determines the region.
- It creates the necessary Terraform file structure (`main.tf`, `variables.tf`, and modules for `instances` and `storage`).

### 2. Importing Existing Instances

- **Goal**: Bring two pre-existing VM instances under Terraform management.
- **Terraform Plan**:
  - `main.tf` is configured to use the `instances` module.
  - `modules/instances/instances.tf` defines two `google_compute_instance` resources (`tf-instance-1`, `tf-instance-2`).
  - The script runs `terraform import` to associate the existing cloud resources with the Terraform resource definitions.
- **Terraform Apply**:
  - `terraform apply` is run to synchronize the state file with the imported resources. No infrastructure changes are made at this point.

### 3. Adding a GCS Bucket

- **Goal**: Create a new Google Cloud Storage bucket.
- **Terraform Plan**:
  - A `storage` module is added to `main.tf`.
  - `modules/storage/storage.tf` is created with a `google_storage_bucket` resource using the bucket name provided by the user.
- **Terraform Apply**:
  - `terraform apply` creates the new GCS bucket in your GCP project.

### 4. Configuring GCS Remote Backend

- **Goal**: Move the Terraform state file from the local machine to the newly created GCS bucket for persistence and collaboration.
- **Terraform Plan**:
  - The `main.tf` file is updated with a `backend "gcs"` block, pointing to the GCS bucket.
  - The script runs `terraform init`, which detects the new backend configuration.
- **Terraform Apply**:
  - `terraform init` prompts to migrate the state. The script automatically answers "yes", and Terraform copies the `terraform.tfstate` file to the GCS bucket.

### 5. Modifying and Adding Instances

- **Goal**: Update the machine type of the existing instances and create a new one.
- **Terraform Plan**:
  - The `modules/instances/instances.tf` file is modified:
    - The `machine_type` for `tf-instance-1` and `tf-instance-2` is changed from `n1-standard-1` to `e2-standard-2`.
    - A new `google_compute_instance` resource is added using the instance name provided by the user.
- **Terraform Apply**:
  - `terraform apply` executes the plan, which updates the two existing instances and creates one new VM instance.

### 6. Tainting a Resource

- **Goal**: Force Terraform to destroy and recreate a specific resource on the next apply.
- **Terraform Plan**:
  - The script runs `terraform taint` on the newly created instance.
  - `terraform plan` will now show that this instance is scheduled for replacement (1 to destroy, 1 to create).
- **Terraform Apply**:
  - `terraform apply` destroys the tainted instance and immediately creates it again.

### 7. Removing an Instance

- **Goal**: Remove the third instance from the infrastructure.
- **Terraform Plan**:
  - The resource block for the third instance is removed from `modules/instances/instances.tf`.
  - `terraform plan` will show that the instance is scheduled for destruction.
- **Terraform Apply**:
  - `terraform apply` destroys the instance that was just recreated.

### 8. Creating a VPC Network

- **Goal**: Add a custom VPC with two subnets using a public Terraform module.
- **Terraform Plan**:
  - `main.tf` is updated to include the `terraform-google-modules/network/google` module.
  - The module is configured to create a VPC and two subnets (`subnet-01` and `subnet-02`) with specified IP ranges.
- **Terraform Apply**:
  - After initializing the new module with `terraform init`, `terraform apply` creates the VPC and its subnets.

### 9. Attaching Instances to the New VPC

- **Goal**: Move the two VM instances from the `default` network to the newly created custom VPC subnets.
- **Terraform Plan**:
  - The `network_interface` block in `modules/instances/instances.tf` for both instances is updated.
  - `tf-instance-1` is assigned to `subnet-01` of the new VPC.
  - `tf-instance-2` is assigned to `subnet-02` of the new VPC.
  - This change requires the instances to be recreated.
- **Terraform Apply**:
  - `terraform apply` destroys the two instances from the default network and recreates them within the new custom VPC subnets.

### 10. Adding a Firewall Rule

- **Goal**: Create a firewall rule to allow HTTP traffic to tagged instances.
- **Terraform Plan**:
  - A `google_compute_firewall` resource is added to `main.tf`.
  - The rule is configured to allow TCP traffic on port 80 from any source (`0.0.0.0/0`) to instances with the `web` tag within the custom VPC.
- **Terraform Apply**:
  - `terraform apply` creates the new firewall rule in the VPC.

### 11. Completion

- The script prints a "Lab Completed Successfully!" message.

---
*This script is for educational purposes and is based on the GSP345 lab guide.*