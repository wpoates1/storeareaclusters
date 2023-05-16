# Pre-Requisites

## Google Cloud
- GCP Account
- GCP Project
- GCP BigQuery Dataset to hold the tables that are being created
- GCP Cloud Storage (GCS) bucket to hold the census data tables 

You can open your account and start your first project at https://cloud.google.com/free. Please take note of the project ID that you use for your project.

**NB for the purposes of this demo it is suggested to just to work in the US Region of GCP for the Storage Bucket and the BigQuery assets. Queries in the console always default to US and I haven't yet found a way of change that setting.**

Google have two overlapping 'free' programmes:
- [Free Trial](https://cloud.google.com/free/docs/free-cloud-features#free-trial): $300 to spend in 90 days for new customers
- [Free Tier](https://cloud.google.com/free/docs/free-cloud-features#free-tier): for 20 Google Cloud services (including BigQuery and Cloud Storgae), there is a certain amount of activity that will be free each month, regardless or not of the Free Trial status. This demonstration can be accomplished easily within that free tier even if your Free Trial has expired.

## SQL Scripts - create local copies and replace placeholders
In this folder (above) you will find a Python script called  `loadsqlscripts.py`. This script will do two things:
- copy all of the SQL in this repository, replacing the `_PROJECT_` and the `_DATASET_` placeholders with the values that you set. This avoids the need to do it manually in all of the SQL snippets;
- initiate a dataset in your Google Cloud project to hold all the work;

An easy way to run this script without needing to worry about your local computing environment and installing the Google Cloud SDK is to use Google's [Cloud Shell Editor](https://cloud.google.com/shell/docs/launching-cloud-shell-editor) in GCP. The Cloud Shell Editor is the equivalent of Visual Studio Code or other common IDE but running on a temporary (zero cost!) Virtual Machine in GCP and using the Web Browser as the user interface.

To use the script:
- (For convenience, it is suggested that you have two browser windows open - one with this GitHub repo and one with your Google Cloud project. Open the Cloud Shell by clicking on the icon towards the top-right corner of the Google Cloud console);
- In the cloud editor, open your workspace;
- Create a new file and give it a name list `loadsql.py`
- In the lines ` "_PROJECT_": "your_project_id"` and `"_DATASET_": "your_dataset_name"` replace `your_project_id` with the name of your GCP project and `your_dataset_name` with the name that you would like to call the BigQuery dataset - remember to leave the string quotes in place;
- execute the python file (press the run icon above and to the right of the code, or press F5)




