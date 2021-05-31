echo "**************************"
echo "##[section]Spinning up batch jobs to test the proposed changes"
echo "**************************"

# Set date, format YYYYMMDD, used to name batch jobs
date=$(date '+%Y%m%d')
echo ""

# Submit Job 1
job1_name="job1"
job1=$(aws batch submit-job --job-name BatchJob1Name_int_$date --job-definition BatchJob1JobDef:2 --job-queue arn:aws:batch:us-east-1:1234567890:job-queue/batch-job-queue-1 --region us-east-1 --container-overrides vcpus=4,memory=8192,command='["-a=foo","-b=bar"]' | jq -r '.jobId')
echo "##[command]"$job1_name "job submitted, ID:" $job1

# Submit Job 1
job2_name="job2"
job2=$(aws batch submit-job --job-name BatchJob2Name_int_$date --job-definition BatchJob2JobDef:2 --job-queue arn:aws:batch:us-east-1:1234567890:job-queue/batch-job-queue-1 --region us-east-1 --container-overrides vcpus=4,memory=8192,command='["-a=foo","-b=bar"]' | jq -r '.jobId')
echo "##[command]"$job2_name "job submitted, ID:" $job2

# Initialize tracking variables
job1_still_checking="yes"
job2_still_checking="yes"

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

    # If any jobs still waiting, loop
    if [ $job1_still_checking = "no" -a $job2_still_checking = "no" ]; then
        echo "##[section]Done checking"
        break
    fi
    sleep 5
done

# If all happy, return 0 exit code. Else return 1 and fail
if [ $job1_results = "SUCCEEDED" ] && [ $job2_results = "SUCCEEDED" ]; then
    echo "##[section]All tests pass"
    exit 0
else
    echo "##[error]At least one test has failed. Either your code or our tests aren't valid."
    echo "##[error]Feel free to run the validations again"
    exit 1
fi
