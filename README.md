# fabric8 workflow builder 

Generic, plugable [custom builder](https://github.com/openshift/origin/blob/master/docs/builds.md#custom-builds) image for working with [OpenShift builds](https://github.com/openshift/origin/blob/master/docs/builds.md#openshift-builds).

Using a [build config](https://github.com/openshift/origin/blob/master/docs/openshift_model.md#buildconfig), [triggers](https://github.com/openshift/origin/blob/master/pkg/build/api/types.go#L276) are defined that will run this image on an event.  [Jenkins workflow](https://wiki.jenkins-ci.org/display/JENKINS/Workflow+Plugin) or build job scripts are copied into the Jenkins jobs directory before starting it, this will then configure all required jobs upon startup.

The workflow or job will be triggered and polled eventually finishing with either success of failure.

## Environment variables

env var | description | example
:---|:---|:---  
SCRIPTS_URI | Git repo that the Jenkins workflow and build job scripts reside.  This can also be the fabric8 wiki. | https://github.com/rawlingsj/fabric8-workflow-scripts.git  
SCRIPTS_PROJECT | the folder within the $SCRIPTS_URI that the project scripts to be used are stored | generic-workflow  
TRIGER_WORKFLOW_JOB | the entry point job to trigger, typically this will be a workflow job name | example-workflow  

## How to use

Set the environment variables above in an OpenShift build config and reference this image as the custom docker image.  When you build trigger is activated this image will..

 * clone the `$SCRIPTS_URI`
 * move the `$SCRIPTS_PROJECT` from within the `$SCRIPTS_URI` to the `$JENKINS_HOME/jobs` directory
 * start Jenkins which in turn takes the scripts in `$JENKINS_HOME/jobs` and automatically configures itself with the correct workflow and build jobs
 * the initial workflow job or a build job is then triggered 
 * the customer builder image waits until the job has finished and exists with either success or failure

 example OpenShift build config..

 		{  
         "apiVersion":"v1beta1",
         "kind":"BuildConfig",
         "metadata":{  
            "labels":{  
               "container":"java",
               "group":"quickstarts"
            },
            "name":"camel-cdi-pipeline"
         },
         "parameters":{  
            "output":{  
               "to":{  
                  "name":"example-camel-cdi"
               }
            },
            "source":{  
               "git":{  
                  "uri":"https://github.com/rawlingsj/example-camel-cdi.git"
               },
               "type":"Git"
            },
            "strategy":{  
               "customStrategy":{  
                  "image":"fabric8/fabric8-workflow-builder",
                  "exposeDockerSocket":true
               },
               "type":"Custom",
               "env":[  
                  {  
                     "name":"SCRIPTS_URI",
                     "value":"https://github.com/rawlingsj/fabric8-workflow-scripts.git"
                  },
                  {  
                     "name":"SCRIPTS_PROJECT",
                     "value":"fabric8-workflow-scripts"
                  },
                  {  
                     "name":"WORKFLOW_PROJECT",
                     "value":"example-workflow"
                  }
               ]
            }
         },
         "triggers":[  
            {  
               "generic":{  
                  "secret":"secret101"
               },
               "type":"generic"
            },
            {  
               "type":"imageChange",
               "imageChange":{  
                  "image":"example-camel-cdi",
                  "from":{  
                     "name":"example-camel-cdi"
                  },
                  "tag":"test"
               }
            }
         ]
 		}

