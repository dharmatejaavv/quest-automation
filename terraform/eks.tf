# Create the EKS cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.35.0"

  cluster_name    = "quest-eks-cluster"
  cluster_version = "1.27"

  # Attach the cluster to the private subnets from your VPC
  subnet_ids = module.vpc.private_subnets

  # Configure the EKS cluster to use a public endpoint (for simplicity)
  cluster_endpoint_public_access = true

  authentication_mode = "API_AND_CONFIG_MAP"

   # Access Entries (AWS-native permissions, replaces aws-auth ConfigMap)
  access_entries = {
    dev-user = {
      principal_arn = "arn:aws:iam::664955381775:user/dev-user" 
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  # Node group configuration (free-tier compatible)
  eks_managed_node_groups = {
    default = {
      instance_type = "t3.micro"  # Free-tier eligible in eu-west-1
      min_size      = 2
      max_size      = 4
      desired_size  = 2
    }
  }

  # Allow worker nodes to join the cluster
  vpc_id = module.vpc.vpc_id
}

# Generate kubeconfig for accessing the cluster
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    command     = "aws"
  }
}

# Output the command to configure kubectl
output "configure_kubectl" {
  description = "Command to configure kubectl access"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region eu-west-1"
}

output "access_ent" {
  value = module.eks.access_entries
}

output "access_policy" {
  value = module.eks.access_policy_associations
}