nextflow.enable.dsl = 2

params.out = "./results"
params.temp = "${baseDir}/downloads" 
params.accession = "accessions.txt"
params.with_fastqc = false
params.with_stats = false
params.with_fastp = false 
/*params.cut_window_size = 4
params.cut_mean_quality = 20
params.length_required = 50
params.average_qual = 20*/

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
    container "https://depot.galaxyproject.org/singularity/sra-tools%3A3.2.1--h4304569_1"
    input: 
        path srafile
    output: 
        path "${srafile.getSimpleName()}*.fastq"
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

process fastqc {
    publishDir "${params.out}/fastqc_reports", mode: "copy", overwrite: true
    container "https://depot.galaxyproject.org/singularity/fastqc%3A0.12.1--hdfd78af_0"
    input:
        path fastqfile
    output:
        path "${fastqfile.getSimpleName()}_fastqc.zip"
        /*path "${fastqfile.getSimpleName()}_fastqc.html"*/
    """
    fastqc -o . ${fastqfile}
    """
}

process fastP {
    publishDir "${params.out}/fastp_reports", mode: "copy", overwrite: true
    container "https://depot.galaxyproject.org/singularity/fastp%3A1.0.1--heae3180_0"
    input:
        path fastqfile
    output: 
        path "${fastqfile.getSimpleName()}_trimmed.fastq"
    """
    fastp --in1 "${fastqfile.getSimpleName()}.fastq" --out1 "${fastqfile.getSimpleName()}_trimmed.fastq"
    """
}

process multiQC {
    publishDir params.out, mode: "copy", overwrite: true
    container "https://depot.galaxyproject.org/singularity/multiqc%3A1.29--pyhdfd78af_0"
    input: 
        path fastqfile
    output: 
        path "multiqc_*"
    """
    multiqc .
    """
}

workflow {
   accessionChannel = channel.fromPath(params.accession).splitText().map{it -> it.trim()} 
   mainChannel = accessionChannel | prefetch | convertToFastq

    if (params.with_stats) {
        generateStats(mainChannel)
    }

    if (params.with_fastqc) {
        qcChannel = fastqc(mainChannel)
    }

    if (params.with_fastp) {
        fastPChannel = fastP(mainChannel)
    }
    
    multiQC(qcChannel.collect())

    /*if (params.with_fastp) {
        mainChannel | fastP
    }*/

    /*if (!params.with_stats && !params.with_fastqc) {
        mainChannel.set { finalfastqc }

        process publishfastq {
            publishDir params.out, mode: "copy", overwrite: true
            input:
                path fastqfile
            output:
                path fastqfile
            """
            echo "Publishing ${fastqfile.name}"
            """
        }
        finalfastqc | publishfastq
    }*/
}