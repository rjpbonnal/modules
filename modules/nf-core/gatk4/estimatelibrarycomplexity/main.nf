process GATK4_ESTIMATELIBRARYCOMPLEXITY {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? "bioconda::gatk4=4.2.6.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gatk4:4.2.6.1--hdfd78af_0':
        'quay.io/biocontainers/gatk4:4.2.6.1--hdfd78af_0' }"

    input:
    tuple val(meta), path(input)
    path  fasta
    path  fai
    path  dict

    output:
    tuple val(meta), path('*.metrics'), emit: metrics
    path "versions.yml"               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def input_list = input.collect(){"--INPUT $it"}.join(" ")

    def avail_mem = 3
    if (!task.memory) {
        log.info '[GATK EstimateLibraryComplexity] Available memory not known - defaulting to 3GB. Specify process memory requirements to change this.'
    } else {
        avail_mem = task.memory.giga
    }
    """
    gatk --java-options "-Xmx${avail_mem}g" EstimateLibraryComplexity \\
        $input_list \\
        --OUTPUT ${prefix}.metrics \\
        --REFERENCE_SEQUENCE ${fasta} \\
        --TMP_DIR . \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: \$(echo \$(gatk --version 2>&1) | sed 's/^.*(GATK) v//; s/ .*\$//')
    END_VERSIONS
    """
}
