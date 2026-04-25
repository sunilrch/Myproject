apiVersion: v1
kind: ServiceAccount
metadata:
  name: node-app-sa
  annotations:
    eks.amazonaws.com/role-arn: {{ .Values.irsaRoleArn }}