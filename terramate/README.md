---
title: Terramate
homepage: https://github.com/terramate-io/terramate
tagline: |
  Terramate simplifies managing large-scale Terraform codebases
---

To update or switch versions, run `webi terramate@stable` (or `@v0.11.4`,
`@beta`, etc).

## Cheat Sheet

> `Terramate` enables scalable automation for Terraform by providing a robust
> framework for managing multiple stacks, generating code, and executing
> targeted workflows.

### **1. Create a New Project**

```sh
git init -b 'main' ./terramate-quickstart
cd ./terramate-quickstart
git commit --allow-empty -m "Initial empty commit"
```

### **2. Create a Stack**

```sh
terramate create \
  --name "StackName" \
  --description "Description of the stack" \
  ./stacks/stackname/

git add ./stacks/stackname/stack.tm.hcl
git commit -m "Create a stack"
```

### **3. List Stacks**

```sh
terramate list
```

### **4. Detect Changes**

```sh
terramate list --changed
```

### **5. Generate Code**

1. Create a `.tm.hcl` file for code generation:

   ```sh
   cat <<EOF > ./stacks/backend.tm.hcl
   generate_hcl "backend.tf" {
     content {
       terraform {
         backend "local" {}
       }
     }
   }
   EOF
   ```

2. Run the generation command:
   ```sh
   terramate generate
   ```

### **6. Run Terraform Commands**

- **Initialize stacks:**

  ```sh
  terramate run terraform init
  ```

- **Plan changes:**

  ```sh
  terramate run terraform plan
  ```

- **Apply changes:**

  ```sh
  terramate run terraform apply -auto-approve
  ```

- **Run commands only on changed stacks:**
  ```sh
  terramate run --changed terraform init
  terramate run --changed terraform plan
  terramate run --changed terraform apply -auto-approve
  ```
