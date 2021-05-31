echo "**************************"
echo "##[section]Spinning up batch jobs to test the proposed changes"
echo "**************************"

# Set date, format YYYYMMDD, used to name batch jobs
date=$(date '+%Y%m%d')
echo ""

# Submit Job 1
job1_name="SalesForce API"
job1=$(aws batch submit-job --job-name AzureAutomation_sfapi_pypeline_inttest_$date --job-definition AutomationPyLoaderJobDef:2 --job-queue arn:aws:batch:us-east-1:198451936645:job-queue/clonrjobqueue --region us-east-1 --container-overrides vcpus=4,memory=8192,command='["-e=int","--source=API","-d=salesforce","-s=dbo","-t=account","--load_type=INCR","--sfload"]' | jq -r '.jobId')
echo "##[command]"$job1_name "job submitted, ID:" $job1

# Submit Job 2 
job2_name="SQL"
job2=$(aws batch submit-job --job-name AzureAutomation_sqlserver_pypeline_inttest_$date --job-definition AutomationPyLoaderJobDef:2 --job-queue arn:aws:batch:us-east-1:198451936645:job-queue/clonrjobqueue --region us-east-1 --container-overrides vcpus=4,memory=8192,command='["-e=int","--source=SS","-d=practicefusionlabs","-s=dbo","-t=lab","--load_type=FULL","--sfload"]' | jq -r '.jobId')
echo "##[command]"$job2_name "job submitted, ID:" $job2

# Submit Job 3 
job3_name="Zuora Api"
job3=$(aws batch submit-job --job-name AzureAutomation_zuoraapi_pypeline_inttest_$date --job-definition AutomationPyLoaderJobDef:2 --job-queue arn:aws:batch:us-east-1:198451936645:job-queue/clonrjobqueue --region us-east-1 --container-overrides vcpus=4,memory=8192,command='["-e=int","--source=API","-d=zuora","-s=dbo","--load_type=INCR","--sfload"]' | jq -r '.jobId')
echo "##[command]"$job3_name "job submitted, ID:" $job3

# Submit Job 4
job4_name="Mongo"
job4=$(aws batch submit-job --job-name AzureAutomation_mongo_pypeline_inttest_$date --job-definition AutomationPyLoaderJobDef:2 --job-queue arn:aws:batch:us-east-1:198451936645:job-queue/clonrjobqueue --region us-east-1 --container-overrides vcpus=4,memory=8192,command='["-d","observations","-t","Observation","--source","MNG","--loadfrom","2021-02-10 00:09:03.5","--loadto","2021-02-12 01:09:03.5","--sfload"]' | jq -r '.jobId')
echo "##[command]"$job4_name "job submitted, ID:" $job4

# Initialize tracking variables
job1_still_checking="yes"
job2_still_checking="yes"
job3_still_checking="yes"
job4_still_checking="yes"

# Start forever loop, will exit when all results are returned
while [ 0=0 ]; do
    echo "##[command]Checking Job status"
    
    if [ $job1_still_checking = "yes" ]; then
        job1_results=$(aws batch describe-jobs --jobs $job1 --region us-east-1 | jq -r '.jobs[].status')
        echo $job1_name "has status:" $job1_results
        case $job1_results in
            "SUCCEEDED")
                echo "##[section]"$job1_name "job succeeded"
                job1_still_checking="no"
                ;;
            "FAILED")
                echo "##[error]"$job1_name "job failed"
                job1_still_checking="no"
                break
                ;;
        esac
    fi

    if [ $job2_still_checking = "yes" ]; then
        job2_results=$(aws batch describe-jobs --jobs $job2 --region us-east-1 | jq -r '.jobs[].status')
        echo $job2_name "has status:" $job2_results
        case $job2_results in
            "SUCCEEDED")
                echo "##[section]"$job2_name "job succeeded"
                job2_still_checking="no"
                ;;
            "FAILED")
                echo "##[error]"$job2_name "job failed"
                job2_still_checking="no"
                break
                ;;
        esac
    fi

    if [ $job3_still_checking = "yes" ]; then
        job3_results=$(aws batch describe-jobs --jobs $job3 --region us-east-1 | jq -r '.jobs[].status')
        echo $job3_name "has status:" $job3_results
        case $job3_results in
            "SUCCEEDED")
                echo "##[section]"$job3_name "job succeeded"
                job3_still_checking="no"
                ;;
            "FAILED")
                echo "##[error]"$job3_name "job failed"
                job3_still_checking="no"
                break
                ;;
        esac
    fi

    if [ $job4_still_checking = "yes" ]; then
        job4_results=$(aws batch describe-jobs --jobs $job4 --region us-east-1 | jq -r '.jobs[].status')
        echo $job4_name "has status:" $job4_results
        case $job4_results in
            "SUCCEEDED")
                echo "##[section]"$job4_name "job succeeded"
                job4_still_checking="no"
                ;;
            "FAILED")
                echo "##[error]"$job4_name "job failed"
                job4_still_checking="no"
                break
                ;;
        esac
    fi

    # If any jobs still waiting, loop
    if [ $job1_still_checking = "no" -a $job2_still_checking = "no" -a $job3_still_checking = "no" -a $job4_still_checking = "no" ]; then
        echo "##[section]Done checking"
        break
    fi
    sleep 5
done

# If all happy, return 0 exit code. Else return 1 and fail
if [ $job1_results = "SUCCEEDED" ] && [ $job2_results = "SUCCEEDED" ] && [ $job3_results = "SUCCEEDED" ] && [ $job4_results = "SUCCEEDED" ]; then
    echo "##[section]All tests pass"
    exit 0
else
    echo "##[error]At least one test has failed. Either your code or our tests aren't valid."
    echo "##[error]Feel free to run the validations again"
    exit 1
fi
