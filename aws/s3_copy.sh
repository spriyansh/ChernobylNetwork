# Create Data
mkdir -p /home/ec2-user/s3 /home/ec2-user/s3/ASV /home/ec2-user/OTU /home/ec2-user/MicrobialData_DBs

# ASVs
aws s3 cp s3://chernobyl-soil-memory-optim/ASV/dada2-rep-seqs.qza /home/ec2-user/s3/
aws s3 cp s3://chernobyl-soil-memory-optim/ASV/dada2-table.qza /home/ec2-user/s3/

# OTUs
aws s3 cp s3://chernobyl-soil-memory-optim/OTU/vcluster-open-ref-rep-seqs.qza /home/ec2-user/s3
aws s3 cp s3://chernobyl-soil-memory-optim/OTU/vcluster-open-ref-table.qza /home/ec2-user/s3

# Metadata
aws s3 cp s3://chernobyl-soil-memory-optim/Qiime2MetadataInput.tsv /home/ec2-user/s3/

# Silva files
aws s3 cp s3://chernobyl-soil-memory-optim/MicrobialData_DBs/silva-138-99-515-806-classifier.qza /home/ec2-user/s3/
aws s3 cp s3://chernobyl-soil-memory-optim/MicrobialData_DBs/silva-138-99-seqs-515-806.qza /home/ec2-user/s3/
aws s3 cp s3://chernobyl-soil-memory-optim/MicrobialData_DBs/taxonomy.tsv /home/ec2-user/s3

# Clone
git clone https://github.com/spriyansh/ChernobylNetwork.git

# Pull 
cd ChernobylNetwork
git checkout aws-split-run
git pull

# Move to work dir
cd aws/nf-flow-memory-run