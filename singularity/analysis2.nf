nextflow.enable.dsl = 2

params.out = "./results"
params.temp = "${baseDir}/downloads" 
params.accession = "SRR1777174"

process prefetch {
    storeDir params.temp
    container "https://depot.galaxyproject.org/singularity/sra-tools%3A3.2.1--h4304569_1"
    input: 
        val accession
    output:
        path "${accession}/${accession}.sra"
    """
    prefetch ${accession}
    """
}

process convertToFastq {
    publishDir params.out, mode: "copy", overwrite: true 
    container "https://depot.galaxyproject.org/singularity/sra-tools%3A3.2.1--h4304569_1"
    input: 
        path srafile
    output: 
        path "${srafile.getSimpleName()}.fastq"
    """
    fasterq-dump --split-3 "${srafile}"
    """
}

process generateStats {
    publishDir params.out, mode: "copy", overwrite: true 
    container "https://depot.galaxyproject.org/singularity/ngsutils%3A0.5.9--py27h9801fc8_5"
    input: 
        path fastqfile
    output:
        path "${fastqfile.getSimpleName()}.stats"
    """
    fastqutils stats ${fastqfile} > ${fastqfile.getSimpleName()}.stats
    """
}

workflow {
    channel.from(params.accession) | prefetch | convertToFastq | generateStats
}