package main

import (
	"context"
	"fmt"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/ecs"
	ecsTypes "github.com/aws/aws-sdk-go-v2/service/ecs/types"
)

var awsConfig aws.Config

func HandleRequest() error {
	awsConfig, err := config.LoadDefaultConfig(context.TODO())
	if err != nil {
		return err
	}

	client := ecs.NewFromConfig(awsConfig)

	var count int32 = 1
	cluster := "sample-cluster"
	taskDef := "sample"
	containerName := "sample"

	_, err = client.RunTask(
		context.TODO(),
		&ecs.RunTaskInput{
			Cluster:        &cluster,
			TaskDefinition: &taskDef,
			Count:          &count,
			LaunchType:     ecsTypes.LaunchTypeFargate,
			NetworkConfiguration: &ecsTypes.NetworkConfiguration{
				AwsvpcConfiguration: &ecsTypes.AwsVpcConfiguration{
					Subnets:        []string{"subnet-02ad4be365c5f37f6"},
					SecurityGroups: []string{"sg-0501b0a3793ddabc7"},
					AssignPublicIp: ecsTypes.AssignPublicIpEnabled,
				},
			},
			Overrides: &ecsTypes.TaskOverride{
				ContainerOverrides: []ecsTypes.ContainerOverride{
					ecsTypes.ContainerOverride{
						Name: &containerName,
					},
				},
			},
		},
	)

	if err != nil {
		fmt.Printf("ecs run task: error: %s\n", err.Error())
	} else {
		fmt.Println("ecs run task: ok")
	}

	return err
}

func main() {
	lambda.Start(HandleRequest)
}
