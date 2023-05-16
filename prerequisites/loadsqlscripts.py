# USE THIS SCRIPT TO LOAD THE SQL FILES FROM THIS REPO INTO A LOCAL DIRECTORY
#  REPLACE THE VALUES IN placeholders TO MATCH YOUR GCP PROJECT AND DATASET
#   THE SCRIPT WILL THEN MAKE SURE THAT THE SQL HAS THOSE VALUES
import os
import subprocess
from pathlib import Path
from google.cloud import bigquery

# Define the search/replace key-value pairs
placeholders = {
    "_PROJECT_": "your_project_id",
    "_DATASET_": "your_dataset_name",
}

# Set environment variable to use the provided project ID
os.environ["GOOGLE_CLOUD_PROJECT"] = placeholders["_PROJECT_"]

# Get the current working directory
current_working_directory = os.getcwd()

# Clone the GitHub repository into the current working directory
repo_url = "https://github.com/wpoates1/storeareaclusters.git"
repo_name = "storeareaclusters"
subprocess.run(["git", "clone", repo_url, os.path.join(current_working_directory, repo_name)])

# Function to replace placeholders in SQL files
def replace_placeholders(file_path, replacements):
    with open(file_path, "r") as f:
        content = f.read()
    
    # Replace the text in the raw SQL, ensuring it is appropriately quote-wrapped
    for search, replace in replacements.items():
        content = content.replace(search, f'"{replace}"')

    with open(file_path, "w") as f:
        f.write(content)

# Find and replace placeholders in all .sql files
repo_path = Path(current_working_directory, repo_name)
sql_files = list(repo_path.glob("**/*.sql"))

for sql_file in sql_files:
    replace_placeholders(sql_file, placeholders)

# Initialize BigQuery client
client = bigquery.Client()

# Create the dataset
dataset_ref = client.dataset(placeholders["_DATASET_"])
dataset = bigquery.Dataset(dataset_ref)
dataset.location = "US"  # Replace with the desired location
dataset = client.create_dataset(dataset)

print(f"Dataset '{placeholders['_DATASET_']}' created in project '{placeholders['_PROJECT_']}'.")
