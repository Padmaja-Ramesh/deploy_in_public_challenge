#! /bin/bash 
yum install nginx -y
yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
systemctl start amazon-ssm-agent
systemctl enable amazon-ssm-agent
echo "<html><body><h1>Hello from other side!!!</h1><h3>You are viewing from ${instance_id}<h3></body></html>" >> /usr/share/nginx/html/index.html
systemctl start nginx

