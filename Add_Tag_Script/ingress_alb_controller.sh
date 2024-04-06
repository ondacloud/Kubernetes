#!/bin/bash
public_a=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=skills-public-a" --query "Subnets[].SubnetId[]" --output text)
public_b=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=skills-public-b" --query "Subnets[].SubnetId[]" --output text)
public_c=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=skills-public-c" --query "Subnets[].SubnetId[]" --output text)
private_a=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=skills-private-a" --query "Subnets[].SubnetId[]" --output text)
private_b=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=skills-private-b" --query "Subnets[].SubnetId[]" --output text)
private_c=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=skills-private-c" --query "Subnets[].SubnetId[]" --output text)

public_subnet_name=("$public_a" "$public_b" "$public_c")
private_subnet_name=("$private_a" "$private_b" "$private_c")

for name in "${public_subnet_name[@]}"
do
    aws ec2 create-tags --resources $name --tags Key=kubernetes.io/role/elb,Value=1
done

for name in "${private_subnet_name[@]}"
do
    aws ec2 create-tags --resources $name --tags Key=kubernetes.io/role/internal-elb,Value=1
done