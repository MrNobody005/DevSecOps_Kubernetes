import os
import base64
from dotenv import load_dotenv

load_dotenv('../../../.env')

keys = ["POSTGRES_DB", "POSTGRES_USER", "POSTGRES_PASSWORD", "SECRET_KEY"]

# Dictionnaire pour stocker les valeurs encodées
encoded = {}

for key in keys:
    value = os.getenv(key)
    if value is None:
        raise ValueError(f"Attention ! {key} n'existe pas dans le .env")
    encoded[key] = base64.b64encode(value.encode()).decode()

# Génération du YAML
yaml_content = "apiVersion: v1\nkind: Secret\nmetadata:\n  name: db-secret\ntype: Opaque\ndata:\n"
for k, v in encoded.items():
    yaml_content += f"  {k}: {v}\n"

# Écrire dans un fichier
with open("../secret-db.yaml", "w") as f:
    f.write(yaml_content)

print("secret-db.yaml généré avec succès !")
