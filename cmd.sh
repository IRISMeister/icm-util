docker exec myicm sh -c "ssh -i /Samples/ssh/insecure -oStrictHostKeyChecking=no ubuntu@52.194.229.190 'curl -s http://169.254.169.254/latest/meta-data/local-ipv4'; echo ''"
docker exec myicm sh -c "ssh -i /Samples/ssh/insecure -oStrictHostKeyChecking=no ubuntu@52.195.12.128 'curl -s http://169.254.169.254/latest/meta-data/local-ipv4'; echo ''"
