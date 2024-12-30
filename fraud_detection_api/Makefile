IMAGE_NAME=fraudapi:latest
REPO_URL=174361135196.dkr.ecr.us-east-1.amazonaws.com/fraud_api:latest

login:
	aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 174361135196.dkr.ecr.us-east-1.amazonaws.com

build:
	docker build -t $(IMAGE_NAME) .

tag: 
	docker tag $(IMAGE_NAME) $(REPO_URL)

push:
	docker push $(REPO_URL)

all: login build tag push