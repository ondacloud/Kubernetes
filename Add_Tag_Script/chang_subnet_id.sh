#!/bin/bash
public_a=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=<env>-public-a" --query "Subnets[].SubnetId[]" --output text)
public_b=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=<env>-public-b" --query "Subnets[].SubnetId[]" --output text)
public_c=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=<env>-public-c" --query "Subnets[].SubnetId[]" --output text)
private_a=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=<env>-private-a" --query "Subnets[].SubnetId[]" --output text)
private_b=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=<env>-private-b" --query "Subnets[].SubnetId[]" --output text)
private_c=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=<env>-private-c" --query "Subnets[].SubnetId[]" --output text)

sed -i "s|public_a|$public_a|g" cluster.yaml
sed -i "s|public_b|$public_b|g" cluster.yaml
sed -i "s|public_c|$public_c|g" cluster.yaml
sed -i "s|private_a|$private_a|g" cluster.yaml
sed -i "s|private_b|$private_b|g" cluster.yaml
sed -i "s|private_c|$private_c|g" cluster.yaml