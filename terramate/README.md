---
title: Terramate
homepage: https://github.com/terramate-io/terramate
tagline: |
  Terramate simplifies managing large-scale Terraform codebases with a focus on automation and scalability.
---

To update or switch versions, run `webi terramate@stable` (or `@v1.0.0`,
`@beta`, etc).

## Cheat Sheet

The information in this section is a copy of the preflight requirements and
common command-line arguments from Terramate
(https://github.com/terramate-io/terramate).

> `Terramate` enables scalable automation for Terraform by providing a robust
> framework for managing multiple stacks, generating code, and executing
> targeted workflows.


### **1. Create a New Project**
```bash
git init -b main terramate-quickstart
cd terramate-quickstart
git commit --allow-empty -m "Initial empty commit"
```

---

### **2. Create a Stack**
```bash
terramate create \
  --name "StackName" \
  --description "Description of the stack" \
  stacks/stackname

git add stacks/stackname/stack.tm.hcl
git commit -m "Create a stack"
```

---

### **3. List Stacks**
```bash
terramate list
```

---

### **4. Detect Changes**
```bash
terramate list --changed
```

---

### **5. Generate Code**
1. Create a `.tm.hcl` file for code generation:
   ```bash
   cat <<EOF >stacks/backend.tm.hcl
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
   ```bash
   terramate generate
   ```

---

### **6. Run Terraform Commands**
- **Initialize stacks:**
  ```bash
  terramate run terraform init
  ```

- **Plan changes:**
  ```bash
  terramate run terraform plan
  ```

- **Apply changes:**
  ```bash
  terramate run terraform apply -auto-approve
  ```

- **Run commands only on changed stacks:**
  ```bash
  terramate run --changed terraform init
  terramate run --changed terraform plan
  terramate run --changed terraform apply -auto-approve
  ```
