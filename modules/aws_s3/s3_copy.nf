// modules/aws_s3/s3_copy.nf

// Copy local files to S3
process CopyLocalToS3Bucket {
    tag "AWS-S3-Copy"
    // debug "true"
    publishDir "${params.output_dir}/AWS_S3_Copy_Logs", mode: 'copy'

    input:
    tuple file(filename), val(prefix)

    output:
    file "${filename}.aws.s3.copy.log.txt"

    script:
    """
    if [ "${prefix}" == "." ]; then
        aws s3 cp ${filename} ${params.bucket}/ --profile ${params.profile} --debug > ${filename}.aws.s3.copy.log.txt
    else
        aws s3 cp ${filename} ${params.bucket}/${prefix}/ --profile ${params.profile} --debug > ${filename}.aws.s3.copy.log.txt
    fi
    """
}
