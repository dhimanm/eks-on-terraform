
# Mukesh 1st Terra EKS Cluster

resource "aws_eks_cluster" "mukesh-eks" {
  name     = local.eks_cluster_name
  role_arn = aws_iam_role.eks_master_role.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = module.vpc.public_subnets
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
  }

  kubernetes_network_config {
    service_ipv4_cidr = var.cluster_service_ipv4_cidr
  }

  # Enable EKS Cluster Control Plane Logging

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]


  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSVPCResourceController,
    aws_iam_role_policy_attachment.eks-AmazonEKSClusterPolicy,
  ]
}

###########################################################

resource "aws_eks_node_group" "mukesh_eks_public_ng" {
  cluster_name    = aws_eks_cluster.mukesh-eks.name
  node_group_name = "${local.name}-eks-public-nodegroup"
  node_role_arn   = aws_iam_role.eks_nodegroup_role.arn
  subnet_ids      = module.vpc.public_subnets
  version         = var.cluster_version

  ami_type       = "AL2_x86_64"
  capacity_type  = "ON_DEMAND"
  disk_size      = 20
  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 3

  }

  update_config {
    #max_unavailable            = 1
    max_unavailable_percentage = 50
  }
/*
  remote_access {
    ec2_ssh_key = "eks-terraform-key"
  }
*/
  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks-AmazonEC2ContainerRegistryReadOnly
  ]

  tags = {
    "Name" = "${local.name}-Public-Node-Group"
  }
}

###########################################################################################

resource "aws_eks_node_group" "mukesh_eks_private_ng" {
  cluster_name    = aws_eks_cluster.mukesh-eks.name
  node_group_name = "${local.name}-eks-private-nodegroup"
  node_role_arn   = aws_iam_role.eks_nodegroup_role.arn
  subnet_ids      = module.vpc.public_subnets
  version         = var.cluster_version

  ami_type       = "AL2_x86_64"
  capacity_type  = "ON_DEMAND"
  disk_size      = 20
  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 2

  }

  update_config {
    #max_unavailable            = 1
    max_unavailable_percentage = 50
  }

/*
 remote_access {
    ec2_ssh_key = "eks-terra-key"
  }
  
*/
  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks-AmazonEC2ContainerRegistryReadOnly
  ]

  tags = {
    "Name" = "${local.name}-Private-Node-Group"
  }
}
