import os
import configparser
import base64
import json
import git
import boto3
import docker
from atlassian import Bitbucket

def execute_tf(conf):
    os.chdir(os.getcwd() + '/tf')

    with open('vars.tfvars','w') as tfvarsfile:
        for k in list(conf.items('aws')):
            tfvarsfile.write(k[0] + "=" +k[1] + "\n")

    os.system("terraform init")
    os.system("terraform plan")
    os.chdir('../')

def delete_tf():
    os.chdir(os.getcwd() + '/tf')

    #Destory bucket
    os.system("terraform plan destroy -target aws_s3_bucket.bucket_name")
    
    #Destory bucket
    os.system("terraform plan destroy -target aws_instance.test")
    os.chdir('../')


def create_bitbucket_repo(conf):
    conf_bitbucket = conf['bitbucket']
    bitbucket = Bitbucket(
        url=conf_bitbucket['url'],
        username=conf_bitbucket['user'],
        password=conf_bitbucket['pwd'])
    
    bitbucket.create_project('sample_project', "Sample Project", description="My Sample project")
    bitbucket.create_repo('sample_project', "sample_repo", forkable=False, is_private=True)

    repo = git.Repo("./")
    with origin.config_writer as cw:
        cw.set("pushurl", conf_bitbucket["url"] + "/your-repo.git")
    repo.git.checkout("-b", "master")
    repo.git.add(update=True)
    repo.index.commit("commit")
    origin = repo.remote(name="origin")
    origin.push()


def build_docker(conf):
    conf_ecs = conf['ecs']
    local_repository = conf_ecs['tag']

    # AWS credentials
    access_key_id = os.environ['access_key_id']
    secret_access_key = os.environ['secret_access_key']
    aws_region = conf['aws']['region']

    # build Docker image
    docker_client = docker.from_env()
    image, build_log = docker_client.images.build(
        path='.', tag=local_repository, rm=True)

    # get AWS ECR login token
    ecr_client = boto3.client(
        'ecr', aws_access_key_id=access_key_id, 
        aws_secret_access_key=secret_access_key, region_name=aws_region)

    ecr_credentials = (
        ecr_client
        .get_authorization_token()
        ['authorizationData'][0])

    ecr_username = 'AWS'

    ecr_password = (
        base64.b64decode(ecr_credentials['authorizationToken'])
        .replace(b'AWS:', b'')
        .decode('utf-8'))

    ecr_url = ecr_credentials['proxyEndpoint']

    # get Docker to login/authenticate with ECR
    docker_client.login(
        username=ecr_username, password=ecr_password, registry=ecr_url)

    # tag image for AWS ECR
    ecr_repo_name = '{}/{}'.format(
        ecr_url.replace('https://', ''), local_repository)

    image.tag(ecr_repo_name, tag='latest')

    # push image to AWS ECR
    push_log = docker_client.images.push(ecr_repo_name, tag='latest')

    # force new deployment of ECS service
    ecs_client = boto3.client(
        'ecs', aws_access_key_id=access_key_id,
        aws_secret_access_key=secret_access_key, region_name=aws_region)

    ecs_client.update_service(
        cluster=conf_ecs['cluster'], service=conf_ecs['service'], forceNewDeployment=True)

    return None


if __name__ == '__main__':
    config = configparser.ConfigParser()
    config.read('config.ini')
    execute_tf(config)
    delete_tf()
    create_bitbucket_repo(config)
    build_docker(config)


