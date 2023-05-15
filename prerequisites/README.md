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
The `loadsqlscripts.py` script will create local copies of the SQL scripts and do a search and replace so that your projectID and chosen dataset values are added.

One easy way of running this is to run the script in the [Cloud Shell Editor](https://cloud.google.com/shell/docs/launching-cloud-shell-editor) in GCP. Copy and paste this script into the editor and run it from the command line. All of the SQL code will then be copied down to that editor, ready for you to copy and paste into the SQL console. 


