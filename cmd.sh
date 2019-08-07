docker exec myicm sh -c "ssh -i /Samples/ssh/insecure -oStrictHostKeyChecking=no ubuntu@52.185.185.122 ip -4 -br a show dev eth0 | awk '{ print \$3}' | awk -F'/' '{ print \$1 }'"
docker exec myicm sh -c "ssh -i /Samples/ssh/insecure -oStrictHostKeyChecking=no ubuntu@52.185.185.121 ip -4 -br a show dev eth0 | awk '{ print \$3}' | awk -F'/' '{ print \$1 }'"
