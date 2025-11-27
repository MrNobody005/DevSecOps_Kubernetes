import subprocess

files = [
    "../secret-db.yaml",
    "../postgres-pvc.yaml",
    "../postgres-deployment.yaml",
    "../service-db.yaml",
    "../django-deployment.yaml",
    "../service-web.yaml",
    "../secret-db.yaml",
    "../configmap-web.yaml"
]

for f in files:
    print(f"Applying {f} ...")
    subprocess.run(["kubectl", "apply", "-f", f], check=True)

subprocess.run(["kubectl", "get", "pods"])
subprocess.run(["kubectl", "get", "svc"])
