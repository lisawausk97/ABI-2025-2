nextflow.enable.dsl = 2

params.out = "/home/lisawausk/ABI-2025-2/fastaexample/"
params.temp = "${baseDir}/downloads"
params.repeat = "GCCGCG"
params.indir = null
params.downloadurl = "wget https://tinyurl.com/cqbatch1"

process downloadFile {
	storeDir params.temp
	output: 
		path "batch1.fasta"
	"""
	wget https://tinyurl.com/cqbatch1 -O batch1.fasta
	"""
}

process countSeqs {
	publishDir params.out, mode: "copy", overwrite: true
	input:
		path fastafile
	output: 
		path "numseqs.txt"
	"""
	grep ">" ${fastafile} | wc -l > numseqs.txt
	"""
}

process splitSeq {
	/*publishDir params.out, mode: "copy", overwrite: true*/
	input:
		path fastafile
	output:
		path "Sequence_0*"
"""
split -l 2 -d --additional-suffix .fasta ${fastafile} Sequence_
"""
}

process countRepeats {
	/*publishDir params.out, mode: "copy", overwrite: true*/
	input:
		path fastafile
	output:
		path "${fastafile.getSimpleName()}_repcount.txt"
"""
grep -o "${params.repeat}" ${fastafile} | wc -l > ${fastafile.getSimpleName()}_repcount.txt
"""
}

process makeSummary {
	input: 
		path infiles
	output: 
		path "summary.csv"
"""
echo "# Sequence number, number of repeats" > summary.csv
for f in \$(ls Sequence_0*_repcount.txt); do echo -n "\$f, " >> summary.csv; cat \$f >> summary.csv; done
"""
}

workflow {
	if(params.downloadurl != null && params.indir == null) {
		downloadChannel = downloadFile()
	} 
	else if(params.indir != null && params.downloadurl == null) {
		downloadChannel = channel.fromPath("${params.indir}/*.fasta")
	}
	else {
		error("Error: Please provide either --downloadurl or --indir on the commandline.")
	}
countSeqs(downloadChannel)
downloadChannel | splitSeq | flatten | countRepeats | collect | makeSummary
}

/*workflow {
	downloadChannel = downloadFile()
	countSeqs(downloadChannel)
	splitChannel = splitSeq(downloadChannel)
	splitChannelflat = splitChannel.flatten()
	countRepeats(splitChannelflat)
	makeSummary(countRepeats.out.collect())
}*/