nextflow.enable.dsl = 2

params.out = "/home/lisawausk/ABI-2025-2/nextflowexercise/"
params.temp = "${baseDir}/downloads" 
params.start = "ATG"
params.stop = "TAA | TAG | TGA"

process downloadFile {
    storeDir params.temp
    output:
       path "sequences.sam"
    """
    wget https://gitlab.com/dabrowskiw/cq-examples/-/raw/master/data/sequences.sam -O sequences.sam
    """
}

process splitSAM {
    input: 
        path samfile
    output:
        path "Sequence_*.sam"
    """
    tail -n +3 ${samfile} | split -l 1 -d --additional-suffix .sam - Sequence_
    """
}

process convertToFasta {
    publishDir params.out, mode: "copy", overwrite: true
    input:
        path samfile
    output:
        path "${samfile.getSimpleName()}.fasta"
  """
  echo -n ">" > ${samfile.getSimpleName()}.fasta
  cat ${samfile} | cut -f 1 >> ${samfile.getSimpleName()}.fasta
  cat ${samfile} | cut -f 10 >> ${samfile.getSimpleName()}.fasta
  """
}

process countStart {
    publishDir params.out, mode: "copy", overwrite: true
    input:
        path fastafile
    output:
        path "${fastafile.getSimpleName()}_startcount.txt"
    """
    grep -o "${params.start}" ${fastafile} | wc -l > ${fastafile.getSimpleName()}_startcount.txt
    """
}

process countStop {
    publishDir params.out, mode: "copy", overwrite: true
    input:
        path fastafile
    output:
        path "${fastafile.getSimpleName()}_stopcount.txt"
    """
    grep -o -E "${params.stop}" ${fastafile} | wc -l > ${fastafile.getSimpleName()}_stopcount.txt
    """
}

process makeSummary {
    publishDir params.out, mode: "copy", overwrite: true
    input: 
        path startcounts
        path stopcounts
    output:
        path "summary.csv"
    """
    for f in \$(ls *count.txt); do echo -n "\$f, " >> summary.csv; cat \$f >> summary.csv; done
    """
}

workflow {
    fastaChannel = (downloadFile | splitSAM | flatten | convertToFasta)
    startChannel = countStart(fastaChannel)
    stopChannel = countStop(fastaChannel)
    makeSummary(startChannel.collect(), stopChannel.collect())
}

    /*mainChannel = downloadFile | splitSAM | flatten | convertToFasta
    startChannel = channel.of(countStart(mainChannel))
    stopChannel = channel.of(countStop(mainChannel))
    summaryChannel = channel.of(makeSummary())
    summaryChannel.concat(startChannel, stopChannel).view()*/

